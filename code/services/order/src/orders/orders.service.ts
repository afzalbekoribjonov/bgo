import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import {
  CANCEL_REASON_CUSTOMER_FAULT,
  DriverCancelReason,
  isDriverCancelReason,
} from '../common/cancel-reasons';
import { DispatchService } from './dispatch.service';
import { DriverInfoClient } from '../driver-client/driver-info.client';
import { DriverLocationService } from '../tracking/driver-location.service';
import { NotificationClient } from '../notification-client/notification.client';
import { PromoService } from '../promo/promo.service';
import { RestaurantClient } from '../restaurant-client/restaurant.client';
import { Tariff, TariffService } from '../tariff/tariff.service';
import { EarningsSummary, summarizeEarnings } from '../common/earnings';
import {
  buildVerticalReport,
  buildVerticalReportRange,
  buildVerticalStats,
  combineVerticalReports,
  periodStart,
  ReportPeriod,
} from '../common/reporting';
import { TaxiService } from '../taxi/taxi.service';
import { ParcelService } from '../parcel/parcel.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { ChatRole, Order, OrderItem, OrderMessage, OrderStatus } from './entities';
import { OrderMessageRepository } from './order-message.repository';
import { OrderRepository } from './order.repository';

export type { ReportPeriod };

/** Yakuniy (muvaffaqiyatli yopilgan) holatlar — aylanma/foyda shulardan. */
const TERMINAL_STATUSES: OrderStatus[] = ['DELIVERED', 'COMPLETED'];
/** Bekor qilingan holatlar. */
const CANCELLED_STATUSES: OrderStatus[] = ['CANCELLED', 'FAILED'];
/** Bu tezlikdan yuqori (km/soat) — Beshariq tumani sharoitida real bo'lmagan, shubhali. */
const SUSPICIOUS_SPEED_KMH = 80;

/** Mijozga ko'rsatiladigan holat xabarlari (push). */
const ORDER_STATUS_MESSAGES: Partial<Record<OrderStatus, string>> = {
  ACCEPTED: 'Buyurtmangiz qabul qilindi',
  PREPARING: 'Buyurtmangiz tayyorlanmoqda',
  READY: 'Buyurtmangiz tayyor',
  ASSIGNED: 'Kuryer biriktirildi',
  PICKED_UP: "Kuryer buyurtmani oldi, yo'lda",
  DELIVERED: 'Buyurtmangiz yetkazildi',
  CANCELLED: 'Buyurtmangiz bekor qilindi',
};

/**
 * Sana chegarasini ms'ga aylantiradi. Faqat sana (YYYY-MM-DD) berilsa,
 * 'start' = kun boshi, 'end' = kun oxiri (mahalliy vaqt).
 */
function parseDayBoundary(
  value: string | undefined,
  edge: 'start' | 'end',
): number | undefined {
  if (!value) return undefined;
  const iso =
    value.length === 10
      ? `${value}T${edge === 'start' ? '00:00:00.000' : '23:59:59.999'}`
      : value;
  const ts = new Date(iso).getTime();
  return Number.isNaN(ts) ? undefined : ts;
}

@Injectable()
export class OrdersService implements OnModuleInit {
  constructor(
    private readonly repo: OrderRepository,
    private readonly restaurant: RestaurantClient,
    private readonly tariff: TariffService,
    private readonly promo: PromoService,
    private readonly taxi: TaxiService,
    private readonly parcel: ParcelService,
    private readonly notifications: NotificationClient,
    private readonly dispatch: DispatchService,
    private readonly driverInfo: DriverInfoClient,
    private readonly messages: OrderMessageRepository,
    private readonly driverLocations: DriverLocationService,
  ) {}

  /** Ovqat narx-konfiguratsiyasi (mijoz ilovasi ustama narxni ko'rsatishi uchun). */
  async foodConfig() {
    const t = await this.tariff.getTariff();
    return {
      serviceThreshold: t.foodServiceThreshold,
      serviceFeeUnder: t.foodServiceFeeUnder,
      serviceFeeOver: t.foodServiceFeeOver,
      deliveryFee: t.deliveryFee,
    };
  }

  /** Mijoz uchun jonli buyurtma — oshxona joylashuvi + kuryer + kuryer joylashuvi. */
  async getOwnedLive(customerId: string, id: string) {
    const order = await this.getOwned(customerId, id);
    const dir = await this.restaurant.getRestaurantDirectory();
    const r = dir.get(order.restaurantId) ?? null;
    let driver: {
      name: string;
      car: string | null;
      plate: string | null;
      phone: string | null;
    } | null = null;
    let driverLocation = null;
    const active = [
      'ACCEPTED',
      'PREPARING',
      'READY',
      'ASSIGNED',
      'IN_PROGRESS',
      'PICKED_UP',
    ].includes(order.status);
    if (order.driverId && active) {
      const [info, phone, loc] = await Promise.all([
        this.driverInfo.getPublic(order.driverId),
        this.driverInfo.getUserPhone(order.driverId),
        this.driverLocations.get(order.driverId),
      ]);
      if (info) {
        driver = {
          name: info.fullName,
          car: info.carName ?? null,
          plate: info.plateNumber ?? null,
          phone,
        };
      }
      driverLocation = loc;
    }
    return {
      ...order,
      restaurant: r
        ? { name: r.name, address: r.address, lat: r.lat, lng: r.lng }
        : null,
      driver,
      driverLocation,
    };
  }

  /** Biriktirilgan kuryerning jonli joylashuvi (xaritada kuzatish). */
  async driverLocationForOrder(customerId: string, id: string) {
    const order = await this.getOwned(customerId, id);
    if (!order.driverId) return null;
    return this.driverLocations.get(order.driverId);
  }

  /**
   * Promokodni buyurtmadan oldin tekshirish — yaroqli bo'lsa {code, discount},
   * aks holda BadRequest (sabab bilan). Usage hisoblagichi oshirilmaydi.
   */
  async promoCheck(code: string, itemsTotal: number) {
    return this.promo.apply(code, itemsTotal);
  }

  /** Mijoz buyurtmani baholaydi (yetkazilgandan keyin). */
  async rate(
    customerId: string,
    id: string,
    rating: number,
    comment?: string,
  ): Promise<Order> {
    const order = await this.getOwned(customerId, id);
    if (order.status !== 'DELIVERED') {
      throw new BadRequestException('Faqat yetkazilgan buyurtmani baholash mumkin');
    }
    if (rating < 1 || rating > 5) {
      throw new BadRequestException("Baho 1-5 oralig'ida bo'lishi kerak");
    }
    return this.repo.setRating(id, rating, comment);
  }

  // ---------- Oshxona↔haydovchi suhbat ----------

  listOrderMessages(orderId: string): Promise<OrderMessage[]> {
    return this.messages.listByOrder(orderId);
  }

  /** Buyurtma shu haydovchiga biriktirilganini tekshiradi (suhbat uchun). */
  async assertDriverOrder(id: string, driverId: string): Promise<void> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.driverId !== driverId) {
      throw new ForbiddenException('Bu buyurtma sizga biriktirilmagan');
    }
  }

  /** Xabar yuborish (oshxona yoki haydovchi). Qarshi tomonga push. */
  async sendOrderMessage(
    orderId: string,
    senderId: string,
    role: ChatRole,
    rawText: string,
  ): Promise<OrderMessage> {
    const order = await this.repo.findById(orderId);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (['DELIVERED', 'COMPLETED', 'CANCELLED', 'FAILED'].includes(order.status)) {
      throw new BadRequestException("Yakunlangan buyurtmada yozib bo'lmaydi");
    }
    const message = await this.messages.create({
      orderId,
      senderId,
      senderRole: role,
      text: rawText.trim(),
    });
    // Oshxona -> haydovchi (qurilma) push; haydovchi -> oshxona panel pollingda ko'radi.
    if (role === 'kitchen' && order.driverId) {
      await this.notifications
        .notify(order.driverId, 'Oshxona xabari', rawText.trim(), {
          type: 'order_chat',
          id: orderId,
        })
        .catch(() => undefined);
    }
    return message;
  }

  private readonly logger = new Logger(OrdersService.name);

  /** Dispatch callback + restart tiklanishi. */
  onModuleInit(): void {
    this.dispatch.setFailHandler((orderId, vertical) => {
      if (vertical === 'food') {
        this.failOrder(orderId, 'Kuryer topilmadi', 'system').catch(() => undefined);
      }
    });
    // Server restart bo'lsa PENDING ovqat buyurtmalarini qayta dispatch qilamiz.
    // 2s kechikish — Prisma va boshqa servislar ulangandan keyin.
    setTimeout(() => {
      this.recoverPendingFoodOrders().catch((e) =>
        this.logger.warn(`Dispatch tiklanishi xatosi: ${(e as Error).message}`),
      );
    }, 2000);
  }

  private async recoverPendingFoodOrders(): Promise<void> {
    const all = await this.repo.findAll();
    const stuck = all.filter(
      (o) => o.status === 'PENDING' && !o.driverId,
    );
    if (stuck.length === 0) return;
    this.logger.log(
      `Dispatch tiklanishi: ${stuck.length} ta ovqat buyurtmasi qayta yuborilmoqda`,
    );
    await Promise.all(stuck.map((o) => this.offerToDrivers(o)));
  }

  /** Har taom uchun xizmat haqi ustamasi (per dona) — chegaraga qarab. */
  private foodMarkup(price: number, t: Tariff): number {
    return price > t.foodServiceThreshold
      ? t.foodServiceFeeOver
      : t.foodServiceFeeUnder;
  }

  /**
   * Ikki tomonlama qabul: oshxona VA haydovchi qabul qilsa — buyurtma
   * tasdiqlanadi (PENDING -> ACCEPTED) va mijozga xabar beriladi.
   */
  private async maybeConfirm(order: Order): Promise<Order> {
    if (
      order.status === 'PENDING' &&
      order.kitchenAcceptedAt &&
      order.driverId
    ) {
      const confirmed = await this.repo.updateStatus(order.id, 'ACCEPTED');
      await this.notifyOrderStatus(confirmed);
      return confirmed;
    }
    return order;
  }

  /**
   * Buyurtma qabul qilinmay bekor bo'ldi (oshxona rad etdi / kuryer topilmadi):
   * CANCELLED + mijozga xabar + oshxona darhol faolsiz (isOpen=false) + dispatch.
   */
  private async failOrder(
    id: string,
    reason: string,
    by: 'kitchen' | 'system' = 'system',
  ): Promise<Order | null> {
    const order = await this.repo.findById(id);
    const closed = ['CANCELLED', 'FAILED', 'DELIVERED', 'COMPLETED'];
    if (!order || closed.includes(order.status)) return order;
    const cancelled = await this.repo.updateStatus(id, 'CANCELLED', {
      by,
      reason,
      driverId: order.driverId,
    });
    this.dispatch.clear(id);
    await this.restaurant.setInactive(order.restaurantId).catch(() => undefined);
    await this.notifications.notify(
      order.customerId,
      'Buyurtma',
      "Hozircha kuryer topilmadi yoki oshxona bilan aloqa qilib bo'lmadi. Uzr!",
      { type: 'order', id, status: 'CANCELLED', reason },
    );
    return cancelled;
  }

  /** Mijozga buyurtma holati o'zgargani haqida push (best-effort). */
  private notifyOrderStatus(order: Order): Promise<void> {
    const body = ORDER_STATUS_MESSAGES[order.status];
    if (!body) return Promise.resolve();
    return this.notifications.notify(order.customerId, 'Buyurtma', body, {
      type: 'order',
      id: order.id,
      status: order.status,
    });
  }

  /**
   * Buyurtma yaratish — narx SERVER tomonda (katalog + tarif). Xizmat haqi
   * har taomga ustama (chegaraga qarab). Yetkazishdan komissiya YO'Q.
   * Yaratishdayoq eng yaqin haydovchiga taklif qilinadi (oshxona bilan parallel).
   */
  async create(customerId: string, dto: CreateOrderDto, locale: string) {
    const menu = await this.restaurant.getMenuItems(dto.restaurantId, locale);
    const tariff = await this.tariff.getTariff();

    const items: OrderItem[] = dto.items.map((cartItem) => {
      const catalogItem = menu.get(cartItem.menuItemId);
      if (!catalogItem) {
        throw new BadRequestException(`Taom topilmadi: ${cartItem.menuItemId}`);
      }
      if (!catalogItem.isAvailable) {
        throw new BadRequestException(`Taom mavjud emas: ${catalogItem.name}`);
      }
      return {
        menuItemId: cartItem.menuItemId,
        nameSnapshot: catalogItem.name,
        priceSnapshot: catalogItem.price, // oshxona narxi (haydovchi to'laydi)
        markup: this.foodMarkup(catalogItem.price, tariff),
        qty: cartItem.qty,
        lineTotal: catalogItem.price * cartItem.qty, // oshxona summasi
      };
    });

    const itemsTotal = items.reduce((sum, i) => sum + i.lineTotal, 0); // oshxonaga
    const serviceFee = items.reduce((sum, i) => sum + i.markup * i.qty, 0); // platforma
    const deliveryFee = tariff.deliveryFee;
    const courierEarning = deliveryFee; // haydovchi yetkazishni to'liq oladi (komissiyasiz)

    let discount = 0;
    let promoCode: string | undefined;
    if (dto.promoCode) {
      const applied = await this.promo.apply(dto.promoCode, itemsTotal);
      discount = applied.discount;
      promoCode = applied.code;
    }

    // Mijoz to'lovi = oshxona summasi + xizmat haqi + yetkazish − chegirma
    const total = itemsTotal + serviceFee + deliveryFee - discount;

    const order = await this.repo.create({
      customerId,
      type: dto.type,
      restaurantId: dto.restaurantId,
      items,
      itemsTotal,
      serviceFee,
      deliveryFee,
      commission: 0,
      courierEarning,
      promoCode,
      discount,
      total,
      paymentType: dto.paymentType,
      address: dto.address,
    });
    if (promoCode) await this.promo.incrementUsage(promoCode);

    // Yaratishdayoq haydovchilarga taklif (oshxona panelida polling'da ko'rinadi).
    this.offerToDrivers(order).catch((e) =>
      this.logger.warn(`Dispatch taklif xatosi: ${(e as Error).message}`),
    );
    return order;
  }

  async getOwned(customerId: string, id: string): Promise<Order> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.customerId !== customerId) {
      throw new ForbiddenException('Bu buyurtma sizga tegishli emas');
    }
    return order;
  }

  listMine(customerId: string) {
    return this.repo.findByCustomer(customerId);
  }

  /** Bekor qilish — faqat egasi va faqat PENDING holatda. */
  async cancel(customerId: string, id: string): Promise<Order> {
    const order = await this.getOwned(customerId, id);
    if (order.status !== 'PENDING') {
      throw new BadRequestException(
        'Buyurtmani faqat tasdiqlanmaguncha bekor qilish mumkin',
      );
    }
    this.dispatch.clear(id);
    return this.repo.updateStatus(id, 'CANCELLED', {
      by: 'customer',
      driverId: order.driverId,
    });
  }

  // ---------- Oshxona (kitchen) ----------
  // TODO(restaurant auth): restaurant roli JWT + egalik tekshiruvi.

  listForRestaurant(restaurantId: string) {
    return this.repo.findByRestaurant(restaurantId);
  }

  async listHistoryForRestaurant(restaurantId: string) {
    const all = await this.repo.findByRestaurant(restaurantId);
    return all.filter((o) =>
      ['DELIVERED', 'COMPLETED', 'CANCELLED', 'FAILED'].includes(o.status),
    );
  }

  async statsForRestaurant(restaurantId: string) {
    const all = await this.repo.findByRestaurant(restaurantId);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayTs = today.getTime();

    const delivered = all.filter((o) =>
      ['DELIVERED', 'COMPLETED'].includes(o.status),
    );
    const todayAll = all.filter(
      (o) => new Date(o.createdAt).getTime() >= todayTs,
    );
    const todayDelivered = delivered.filter(
      (o) => new Date(o.createdAt).getTime() >= todayTs,
    );

    // Oshxona daromadi = itemsTotal (haydovchi to'laydigan summa)
    const totalRevenue = delivered.reduce((s, o) => s + o.itemsTotal, 0);
    const todayRevenue = todayDelivered.reduce((s, o) => s + o.itemsTotal, 0);

    // Haftalik kunlik grafik (oxirgi 7 kun)
    const weekMap = new Map<string, { orders: number; revenue: number }>();
    const dayMs = 86_400_000;
    const weekStart = todayTs - 6 * dayMs;
    for (let t = weekStart; t <= Date.now(); t += dayMs) {
      const key = new Date(t).toISOString().slice(0, 10);
      weekMap.set(key, { orders: 0, revenue: 0 });
    }
    for (const o of delivered) {
      const ts = new Date(o.createdAt).getTime();
      if (ts < weekStart) continue;
      const key = o.createdAt.slice(0, 10);
      const cur = weekMap.get(key) ?? { orders: 0, revenue: 0 };
      cur.orders += 1;
      cur.revenue += o.itemsTotal;
      weekMap.set(key, cur);
    }
    const weekly = Array.from(weekMap.entries()).map(([date, v]) => ({
      date,
      ...v,
    }));

    return {
      totalOrders: all.length,
      totalDelivered: delivered.length,
      totalRevenue,
      todayOrders: todayAll.length,
      todayDelivered: todayDelivered.length,
      todayRevenue,
      cancelledToday: todayAll.filter((o) =>
        ['CANCELLED', 'FAILED'].includes(o.status),
      ).length,
      avgOrderValue:
        delivered.length > 0 ? Math.round(totalRevenue / delivered.length) : 0,
      weekly,
    };
  }

  /** Buyurtmaning oshxonasi (egalik tekshiruvi uchun). */
  async restaurantIdOf(id: string): Promise<string> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    return order.restaurantId;
  }

  /** Oshxona qabul qildi — kitchenAcceptedAt; ikkalasi bo'lsa tasdiqlanadi. */
  async acceptByRestaurant(id: string): Promise<Order> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.kitchenAcceptedAt) return order; // takror qabul — no-op
    if (order.status !== 'PENDING') {
      throw new BadRequestException('Buyurtma qabul qilish bosqichida emas');
    }
    const withKitchen = await this.repo.setKitchenAccepted(id);
    return this.maybeConfirm(withKitchen);
  }

  startPreparing(id: string) {
    return this.transition(id, ['ACCEPTED'], 'PREPARING');
  }

  /** Tayyor (ACCEPTED/PREPARING -> READY). Dispatch yaratishda bo'lgan. */
  async markReady(id: string) {
    return this.transition(id, ['ACCEPTED', 'PREPARING'], 'READY');
  }

  /** Ovqat buyurtmasini eng yaqin haydovchiga taklif qiladi (oshxona = pickup). */
  private async offerToDrivers(order: Order): Promise<void> {
    const dir = await this.restaurant.getRestaurantDirectory();
    const r = dir.get(order.restaurantId);
    if (!r) return;
    await this.dispatch.offer({
      orderId: order.id,
      vertical: 'food',
      pickupLat: r.lat,
      pickupLng: r.lng,
      pickupName: r.name,
      dropoffLat: order.address.lat ?? null,
      dropoffLng: order.address.lng ?? null,
      dropoffText: order.address.text,
      amount: order.total,
      earning: order.courierEarning,
      foodItemsTotal: order.itemsTotal, // oshxonaga naqd
      foodServiceFee: order.serviceFee, // balansdan
    });
  }

  /** Oshxona rad etdi — bekor + mijozga xabar + oshxona faolsiz. */
  async rejectByRestaurant(id: string): Promise<Order> {
    const cancelled = await this.failOrder(id, 'Oshxona buyurtmani rad etdi', 'kitchen');
    if (!cancelled) throw new NotFoundException('Buyurtma topilmadi');
    return cancelled;
  }

  // ---------- Admin / hisobot ----------
  // TODO(admin auth): admin roli JWT. Hozir ochiq (dev).

  /** Buyurtma foydasi = xizmat haqi − chegirma (yetkazishdan komissiya yo'q). */
  private orderProfit(o: Order): number {
    return o.serviceFee - o.discount;
  }

  async adminStats() {
    const orders = await this.repo.findAll();
    const closed = [...TERMINAL_STATUSES, ...CANCELLED_STATUSES];

    const byStatus: Record<string, number> = {};
    let today = 0;
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    for (const o of orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
      if (new Date(o.createdAt) >= startOfDay) today += 1;
    }

    // Vertikallar bo'yicha aylanma/foyda (ovqat + taksi + dostavka)
    const food = buildVerticalStats(orders, {
      isDone: (o) => TERMINAL_STATUSES.includes(o.status),
      revenueOf: (o) => o.total,
      profitOf: (o) => this.orderProfit(o),
    });
    const [taxi, parcel] = await Promise.all([
      this.taxi.adminStats(),
      this.parcel.adminStats(),
    ]);

    return {
      // Ovqat buyurtmalari (mavjud maydonlar)
      totalOrders: orders.length,
      activeOrders: orders.filter((o) => !closed.includes(o.status)).length,
      todayOrders: today,
      byStatus,
      // Birlashgan moliya (uchala vertikal)
      revenue: food.revenue + taxi.revenue + parcel.revenue,
      profit: food.profit + taxi.profit + parcel.profit,
      byVertical: { food, taxi, parcel },
    };
  }

  /** Davr hisoboti (bugun/hafta/oy) — uchala vertikal jamlangan. */
  async adminReport(period: ReportPeriod) {
    const orders = await this.repo.findAll();
    const food = buildVerticalReport(orders, period, {
      createdAtOf: (o) => o.createdAt,
      isDone: (o) => TERMINAL_STATUSES.includes(o.status),
      isCancelled: (o) => CANCELLED_STATUSES.includes(o.status),
      revenueOf: (o) => o.total,
      profitOf: (o) => this.orderProfit(o),
    });
    const [taxi, parcel] = await Promise.all([
      this.taxi.adminReport(period),
      this.parcel.adminReport(period),
    ]);
    const all = combineVerticalReports([food, taxi, parcel]);

    return {
      period,
      from: periodStart(period).toISOString(),
      to: new Date().toISOString(),
      summary: {
        totalOrders: all.count,
        delivered: all.delivered,
        cancelled: all.cancelled,
        revenue: all.revenue,
        profit: all.profit,
        avgOrder: all.delivered > 0 ? Math.round(all.revenue / all.delivered) : 0,
      },
      daily: all.daily,
      byVertical: {
        food: { revenue: food.revenue, profit: food.profit, delivered: food.delivered },
        taxi: { revenue: taxi.revenue, profit: taxi.profit, delivered: taxi.delivered },
        parcel: { revenue: parcel.revenue, profit: parcel.profit, delivered: parcel.delivered },
      },
    };
  }

  /**
   * Ixtiyoriy sana oralig'i hisoboti — istalgan kun yoki oyni tanlab ko'rish
   * uchun (admin buyurtmalar sahifasi). `to` kun oxirigacha (23:59:59.999).
   */
  async adminReportRange(fromDate: string, toDate: string) {
    const from = new Date(`${fromDate}T00:00:00.000`);
    const to = new Date(`${toDate}T23:59:59.999`);
    const orders = await this.repo.findAll();
    const food = buildVerticalReportRange(orders, from, to, {
      createdAtOf: (o) => o.createdAt,
      isDone: (o) => TERMINAL_STATUSES.includes(o.status),
      isCancelled: (o) => CANCELLED_STATUSES.includes(o.status),
      revenueOf: (o) => o.total,
      profitOf: (o) => this.orderProfit(o),
    });
    const [taxi, parcel] = await Promise.all([
      this.taxi.adminReportRange(from, to),
      this.parcel.adminReportRange(from, to),
    ]);
    const all = combineVerticalReports([food, taxi, parcel]);

    return {
      from: from.toISOString(),
      to: to.toISOString(),
      summary: {
        totalOrders: all.count,
        delivered: all.delivered,
        cancelled: all.cancelled,
        revenue: all.revenue,
        profit: all.profit,
        avgOrder: all.delivered > 0 ? Math.round(all.revenue / all.delivered) : 0,
      },
      daily: all.daily,
      byVertical: {
        food: { revenue: food.revenue, profit: food.profit, delivered: food.delivered },
        taxi: { revenue: taxi.revenue, profit: taxi.profit, delivered: taxi.delivered },
        parcel: { revenue: parcel.revenue, profit: parcel.profit, delivered: parcel.delivered },
      },
    };
  }

  /** Uchala vertikal uchun birlashtrilgan admin buyurtmalar ro'yxati. */
  async adminListOrders(filter: {
    status?: string;
    type?: string;
    from?: string;
    to?: string;
    q?: string;
    sort?: 'createdAt' | 'total';
    order?: 'asc' | 'desc';
    driverId?: string;
  }) {
    const fromTs = parseDayBoundary(filter.from, 'start');
    const toTs = parseDayBoundary(filter.to, 'end');
    const q = filter.q?.trim().toLowerCase();
    const subFilter = { status: filter.status, from: filter.from, to: filter.to, driverId: filter.driverId, q: filter.q };

    type AdminRow = {
      id: string; publicNo: number; type: string; status: string;
      total: number; address: { text: string }; createdAt: string; driverId?: string;
    };

    const rows: AdminRow[] = [];

    // -- FOOD --
    if (!filter.type || filter.type === 'FOOD') {
      const food = (await this.repo.findAll()).filter((o) => {
        if (filter.status && o.status !== filter.status) return false;
        if (filter.driverId && o.driverId !== filter.driverId) return false;
        const ts = new Date(o.createdAt).getTime();
        if (fromTs !== undefined && ts < fromTs) return false;
        if (toTs !== undefined && ts > toTs) return false;
        if (q) {
          const hay = `${o.publicNo} ${o.address?.text ?? ''}`.toLowerCase();
          if (!hay.includes(q)) return false;
        }
        return true;
      });
      for (const o of food) {
        rows.push({ id: o.id, publicNo: o.publicNo, type: 'FOOD', status: o.status, total: o.total, address: o.address, createdAt: o.createdAt, driverId: o.driverId });
      }
    }

    // -- TAXI --
    if (!filter.type || filter.type === 'TAXI') {
      const trips = await this.taxi.adminListTrips(subFilter);
      for (const t of trips) {
        rows.push({ id: t.id, publicNo: t.publicNo, type: 'TAXI', status: t.status, total: t.fare, address: { text: t.pickup?.text ?? '' }, createdAt: t.createdAt, driverId: t.driverId });
      }
    }

    // -- PARCEL --
    if (!filter.type || filter.type === 'PARCEL') {
      const parcels = await this.parcel.adminListDeliveries(subFilter);
      for (const p of parcels) {
        rows.push({ id: p.id, publicNo: p.publicNo, type: 'PARCEL', status: p.status, total: p.fare, address: { text: p.pickup?.text ?? '' }, createdAt: p.createdAt, driverId: p.driverId });
      }
    }

    const sortKey = filter.sort ?? 'createdAt';
    const dir = filter.order === 'asc' ? 1 : -1;
    rows.sort((a, b) => {
      const av = sortKey === 'total' ? a.total : new Date(a.createdAt).getTime();
      const bv = sortKey === 'total' ? b.total : new Date(b.createdAt).getTime();
      return (av - bv) * dir;
    });
    return rows;
  }

  /** Yakunlangan (DELIVERED/COMPLETED) yozuv uchun umumiy davomiylik (daqiqa). */
  private durationMinOf(status: string, createdAt: string, updatedAt: string): number | undefined {
    if (!['DELIVERED', 'COMPLETED'].includes(status)) return undefined;
    const ms = new Date(updatedAt).getTime() - new Date(createdAt).getTime();
    return ms > 0 ? Math.round(ms / 60000) : 0;
  }

  /** "Harakat boshlanishi" holatidan (yo'lovchi/posilka olindi) yakungacha bo'lgan vaqt (daqiqa). */
  private drivingDurationMin(
    history: { status: string; at: string }[] | undefined,
    startStatus: string,
    endStatus: string,
  ): number | undefined {
    const start = (history ?? []).find((h) => h.status === startStatus);
    if (!start) return undefined;
    const end = (history ?? []).find((h) => h.status === endStatus);
    const s = Date.parse(start.at);
    const e = end ? Date.parse(end.at) : Date.now();
    return Math.max(0, Math.round((e - s) / 60000));
  }

  /**
   * Safar real bo'lmagan tezlikda yoki bir zumda yakunlanganmi (haydovchi
   * haqiqatda yo'lni bosib o'tmagan bo'lishi mumkin — jarima/tekshiruv
   * uchun belgi). plan asosida: "Shubhali haydovchilar".
   */
  private speedFlag(
    distanceKm: number,
    durationMin: number | undefined,
  ): { suspicious: boolean; speedKmh: number | null } {
    if (durationMin === undefined || distanceKm <= 0) {
      return { suspicious: false, speedKmh: null };
    }
    if (durationMin < 1) {
      // 1 daqiqadan kamda tugagan — mazkur masofa uchun deyarli imkonsiz.
      return { suspicious: distanceKm > 0.3, speedKmh: null };
    }
    const speedKmh = Math.round((distanceKm / durationMin) * 60);
    return { suspicious: speedKmh > SUSPICIOUS_SPEED_KMH, speedKmh };
  }

  /**
   * "Shubhali haydovchilar" — real bo'lmagan tezlikda/bir zumda yakunlangan
   * safarlar (uchala vertikal), haydovchi bo'yicha guruhlangan. Admin panel.
   */
  async adminSuspiciousTrips() {
    const [food, trips, parcels] = await Promise.all([
      this.repo.findAll(),
      this.taxi.adminListTrips({}),
      this.parcel.adminListDeliveries({}),
    ]);

    type Flag = {
      id: string;
      publicNo: number;
      type: 'FOOD' | 'TAXI' | 'PARCEL';
      distanceKm: number;
      durationMin: number;
      speedKmh: number | null;
      createdAt: string;
      driverId: string;
    };
    const flags: Flag[] = [];

    for (const o of food) {
      if (o.status !== 'DELIVERED' || !o.driverId) continue;
      const distance = o.actualDistanceKm ?? 0;
      const dur = this.drivingDurationMin(o.statusHistory, 'PICKED_UP', 'DELIVERED');
      const { suspicious, speedKmh } = this.speedFlag(distance, dur);
      if (suspicious) {
        flags.push({ id: o.id, publicNo: o.publicNo, type: 'FOOD', distanceKm: distance, durationMin: dur ?? 0, speedKmh, createdAt: o.createdAt, driverId: o.driverId });
      }
    }
    for (const t of trips) {
      if (t.status !== 'COMPLETED' || !t.driverId) continue;
      const distance = t.actualDistanceKm ?? t.distanceKm;
      const dur = this.drivingDurationMin(t.statusHistory, 'IN_PROGRESS', 'COMPLETED');
      const { suspicious, speedKmh } = this.speedFlag(distance, dur);
      if (suspicious) {
        flags.push({ id: t.id, publicNo: t.publicNo, type: 'TAXI', distanceKm: distance, durationMin: dur ?? 0, speedKmh, createdAt: t.createdAt, driverId: t.driverId });
      }
    }
    for (const p of parcels) {
      if (p.status !== 'DELIVERED' || !p.driverId) continue;
      const distance = p.actualDistanceKm ?? p.distanceKm;
      const dur = this.drivingDurationMin(p.statusHistory, 'IN_TRANSIT', 'DELIVERED');
      const { suspicious, speedKmh } = this.speedFlag(distance, dur);
      if (suspicious) {
        flags.push({ id: p.id, publicNo: p.publicNo, type: 'PARCEL', distanceKm: distance, durationMin: dur ?? 0, speedKmh, createdAt: p.createdAt, driverId: p.driverId });
      }
    }

    const byDriver = new Map<string, Flag[]>();
    for (const f of flags) {
      const arr = byDriver.get(f.driverId) ?? [];
      arr.push(f);
      byDriver.set(f.driverId, arr);
    }
    const driverIds = Array.from(byDriver.keys());
    const infos = await Promise.all(driverIds.map((id) => this.driverInfo.getPublic(id)));
    const infoMap = new Map(driverIds.map((id, i) => [id, infos[i]]));

    const speedFlagged = driverIds
      .map((driverId) => {
        const driverFlags = (byDriver.get(driverId) ?? []).sort(
          (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
        );
        const info = infoMap.get(driverId);
        return {
          driverId,
          driverName: info?.fullName ?? null,
          carName: info?.carName ?? null,
          plateNumber: info?.plateNumber ?? null,
          flagCount: driverFlags.length,
          trips: driverFlags,
        };
      })
      .sort((a, b) => b.flagCount - a.flagCount);

    // Ketma-ket (uzluksiz) 3tadan ortiq bekor qilgan haydovchilar — alohida
    // ro'yxat (auth servisidagi hisoblagichdan, har cancel/complete hodisasida
    // yangilanadi — statusHistory'ni har safar skanerlashdan ko'ra tezroq).
    const cancellationFlagged = (
      await this.driverInfo.listHighCancellations(3)
    ).map((d) => ({
      driverId: d.userId,
      driverName: d.driverName,
      carName: d.carName,
      plateNumber: d.plateNumber,
      consecutiveCancellations: d.consecutiveCancellations,
    }));

    return { speedFlagged, cancellationFlagged };
  }

  /** Bekor/muvaffaqiyatsiz bo'lsa — oxirgi holat yozuvidan kim/qachon/nima sabab. */
  private lastActorOf(status: string, history: { status: string; at: string; by?: string; reason?: string }[]) {
    if (!['CANCELLED', 'FAILED'].includes(status)) return {};
    const entry = [...(history ?? [])].reverse().find((h) => h.status === status);
    if (!entry) return {};
    return { cancelledBy: entry.by, cancelledAt: entry.at, cancelReason: entry.reason };
  }

  /** Haydovchining barcha vertikallardagi buyurtmalar tarixi (admin) — to'liq: mijoz, masofa, vaqt, komissiya. */
  async adminDriverHistory(driverId: string) {
    const [food, trips, parcels] = await Promise.all([
      this.repo.findByDriver(driverId),
      this.taxi.adminListTrips({ driverId }),
      this.parcel.adminListDeliveries({ driverId }),
    ]);

    const customerIds = Array.from(
      new Set([...food, ...trips, ...parcels].map((o) => o.customerId)),
    );
    const customerInfos = await Promise.all(
      customerIds.map((cid) => this.driverInfo.getUserInfo(cid)),
    );
    const customerMap = new Map(customerIds.map((cid, i) => [cid, customerInfos[i]]));

    type Row = {
      id: string; publicNo: number; type: string; status: string;
      total: number; earning: number; commission: number;
      distanceKm?: number; durationMin?: number;
      address: string; createdAt: string; updatedAt: string;
      customerName?: string | null; customerPhone?: string | null;
      cancelledBy?: string; cancelledAt?: string; cancelReason?: string;
    };
    const rows: Row[] = [
      ...food.map((o) => {
        const c = customerMap.get(o.customerId);
        return {
          id: o.id, publicNo: o.publicNo, type: 'FOOD', status: o.status,
          total: o.total, earning: o.courierEarning, commission: o.serviceFee,
          durationMin: this.durationMinOf(o.status, o.createdAt, o.updatedAt),
          address: o.address?.text ?? '', createdAt: o.createdAt, updatedAt: o.updatedAt,
          customerName: c?.fullName ?? null, customerPhone: c?.phone ?? null,
          ...this.lastActorOf(o.status, o.statusHistory),
        };
      }),
      ...trips.map((t) => {
        const c = customerMap.get(t.customerId);
        return {
          id: t.id, publicNo: t.publicNo, type: 'TAXI', status: t.status,
          total: t.fare, earning: t.driverEarning, commission: t.commission,
          distanceKm: t.distanceKm, durationMin: this.durationMinOf(t.status, t.createdAt, t.updatedAt),
          address: t.pickup?.text ?? '', createdAt: t.createdAt, updatedAt: t.updatedAt,
          customerName: c?.fullName ?? null, customerPhone: c?.phone ?? null,
          ...this.lastActorOf(t.status, t.statusHistory),
        };
      }),
      ...parcels.map((p) => {
        const c = customerMap.get(p.customerId);
        return {
          id: p.id, publicNo: p.publicNo, type: 'PARCEL', status: p.status,
          total: p.fare, earning: p.driverEarning, commission: p.commission,
          distanceKm: p.distanceKm, durationMin: this.durationMinOf(p.status, p.createdAt, p.updatedAt),
          address: p.pickup?.text ?? '', createdAt: p.createdAt, updatedAt: p.updatedAt,
          customerName: c?.fullName ?? null, customerPhone: c?.phone ?? null,
          ...this.lastActorOf(p.status, p.statusHistory),
        };
      }),
    ];
    rows.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    return rows;
  }

  /** Haydovchi statistikasi — daromad + platforma foydasi bugun/hafta/oy (admin). */
  /** Haydovchi statistikasi — bugun/hafta/oy YOKI 'all' (butun tarix, boshidan hozirgacha). */
  async adminDriverStats(driverId: string, period: ReportPeriod | 'all') {
    const startTs = period === 'all' ? 0 : periodStart(period).getTime();
    const [food, trips, parcels] = await Promise.all([
      this.repo.findByDriver(driverId),
      this.taxi.adminListTrips({ driverId }),
      this.parcel.adminListDeliveries({ driverId }),
    ]);
    let orders = 0, earning = 0, profit = 0;
    let foodOrders = 0, foodEarning = 0;
    let taxiOrders = 0, taxiEarning = 0;
    let parcelOrders = 0, parcelEarning = 0;
    let cancelled = 0;
    for (const o of food) {
      if (new Date(o.createdAt).getTime() < startTs) continue;
      if (['CANCELLED', 'FAILED'].includes(o.status)) { cancelled++; continue; }
      if (o.status !== 'DELIVERED') continue;
      orders++; earning += o.courierEarning; profit += o.serviceFee;
      foodOrders++; foodEarning += o.courierEarning;
    }
    for (const t of trips) {
      if (new Date(t.createdAt).getTime() < startTs) continue;
      if (t.status === 'CANCELLED') { cancelled++; continue; }
      if (t.status !== 'COMPLETED') continue;
      orders++; earning += t.driverEarning; profit += t.commission;
      taxiOrders++; taxiEarning += t.driverEarning;
    }
    for (const p of parcels) {
      if (new Date(p.createdAt).getTime() < startTs) continue;
      if (p.status === 'CANCELLED') { cancelled++; continue; }
      if (p.status !== 'DELIVERED') continue;
      orders++; earning += p.driverEarning; profit += p.commission;
      parcelOrders++; parcelEarning += p.driverEarning;
    }
    return {
      period,
      orders,
      earning,
      profit,
      cancelled,
      byVertical: {
        food: { orders: foodOrders, earning: foodEarning },
        taxi: { orders: taxiOrders, earning: taxiEarning },
        parcel: { orders: parcelOrders, earning: parcelEarning },
      },
    };
  }

  /** Admin: biror buyurtmani (food/taxi/parcel) majburiy bekor qiladi. */
  async adminCancelById(id: string): Promise<{ cancelled: boolean; type: string }> {
    // Avval food orderlarda izlaymiz
    const food = await this.repo.findById(id);
    if (food) {
      if (!['CANCELLED', 'FAILED', 'DELIVERED'].includes(food.status)) {
        this.dispatch.clear(id);
        await this.repo.updateStatus(id, 'CANCELLED', {
          by: 'admin',
          driverId: food.driverId,
        });
      }
      return { cancelled: true, type: 'FOOD' };
    }
    // Taksi
    const taxiResult = await this.taxi.adminCancel(id);
    if (taxiResult) return { cancelled: true, type: 'TAXI' };
    // Dostavka
    const parcelResult = await this.parcel.adminCancel(id);
    if (parcelResult) return { cancelled: true, type: 'PARCEL' };
    return { cancelled: false, type: 'UNKNOWN' };
  }

  /**
   * Jonli xarita (admin): barcha online haydovchilar — joylashuv, yo'nalish,
   * band/bo'sh holati (faol taksi/ovqat/dostavka bo'yicha) va nomi/mashinasi.
   */
  async adminLiveDrivers() {
    const locs = await this.driverLocations.listOnline();
    if (locs.length === 0) {
      return { counts: { online: 0, busy: 0, free: 0 }, drivers: [] };
    }

    // Band haydovchilar — uchala vertikaldagi faol buyurtmalar bo'yicha.
    const [foodAll, trips, parcels] = await Promise.all([
      this.repo.findAll(),
      this.taxi.adminListTrips({}),
      this.parcel.adminListDeliveries({}),
    ]);
    const busySet = new Set<string>();
    const activeFood = [
      'PENDING', 'ACCEPTED', 'PREPARING', 'READY',
      'ASSIGNED', 'IN_PROGRESS', 'PICKED_UP',
    ];
    for (const o of foodAll) {
      if (o.driverId && activeFood.includes(o.status)) busySet.add(o.driverId);
    }
    for (const t of trips) {
      if (t.driverId && ['ACCEPTED', 'ARRIVED', 'IN_PROGRESS'].includes(t.status)) {
        busySet.add(t.driverId);
      }
    }
    for (const p of parcels) {
      if (
        p.driverId &&
        ['ACCEPTED', 'ARRIVED', 'PICKED_UP', 'IN_TRANSIT'].includes(p.status)
      ) {
        busySet.add(p.driverId);
      }
    }

    const infos = await Promise.all(
      locs.map((l) => this.driverInfo.getPublic(l.driverId)),
    );
    const drivers = locs.map((l, i) => ({
      driverId: l.driverId,
      lat: l.lat,
      lng: l.lng,
      heading: l.heading ?? null,
      busy: busySet.has(l.driverId),
      name: infos[i]?.fullName ?? null,
      car: infos[i]?.carName ?? null,
      plate: infos[i]?.plateNumber ?? null,
    }));
    const busy = drivers.filter((d) => d.busy).length;
    return {
      counts: { online: drivers.length, busy, free: drivers.length - busy },
      drivers,
    };
  }

  /**
   * Bitta buyurtmaning to'liq holati (admin — alohida sahifa): barcha narx
   * maydonlari, mijoz/haydovchi/oshxona nomi-telefoni va statusHistory
   * (har o'tishda kim/qachon, tarixiy haydovchi ismi bilan).
   */
  async adminOrderDetail(id: string, type: 'FOOD' | 'TAXI' | 'PARCEL') {
    if (type === 'FOOD') {
      const order = await this.repo.findById(id);
      if (!order) throw new NotFoundException('Buyurtma topilmadi');
      const [customer, driver, dir] = await Promise.all([
        this.driverInfo.getUserInfo(order.customerId),
        order.driverId ? this.driverInfo.getPublic(order.driverId) : null,
        this.restaurant.getRestaurantDirectory(),
      ]);
      const driverPhone = order.driverId
        ? await this.driverInfo.getUserPhone(order.driverId)
        : null;
      const restaurant = dir.get(order.restaurantId) ?? null;
      return {
        id: order.id, publicNo: order.publicNo, type: 'FOOD', status: order.status,
        createdAt: order.createdAt, updatedAt: order.updatedAt,
        customer: { id: order.customerId, name: customer?.fullName ?? null, phone: customer?.phone ?? null },
        driver: order.driverId
          ? { id: order.driverId, name: driver?.fullName ?? null, phone: driverPhone, car: driver?.carName ?? null, plate: driver?.plateNumber ?? null }
          : null,
        restaurant: restaurant
          ? { id: order.restaurantId, name: restaurant.name, address: restaurant.address, lat: restaurant.lat, lng: restaurant.lng }
          : null,
        address: order.address,
        actualDistanceKm: order.actualDistanceKm ?? null,
        items: order.items,
        itemsTotal: order.itemsTotal,
        serviceFee: order.serviceFee,
        deliveryFee: order.deliveryFee,
        courierEarning: order.courierEarning,
        promoCode: order.promoCode ?? null,
        discount: order.discount,
        total: order.total,
        paymentType: order.paymentType,
        kitchenAcceptedAt: order.kitchenAcceptedAt ?? null,
        driverAcceptedAt: order.driverAcceptedAt ?? null,
        rating: order.rating ?? null,
        ratingComment: order.ratingComment ?? null,
        statusHistory: await this.enrichHistory(order.statusHistory),
      };
    }

    if (type === 'TAXI') {
      const trip = await this.taxi.adminGetById(id);
      if (!trip) throw new NotFoundException('Safar topilmadi');
      const [customer, driver] = await Promise.all([
        this.driverInfo.getUserInfo(trip.customerId),
        trip.driverId ? this.driverInfo.getPublic(trip.driverId) : null,
      ]);
      const driverPhone = trip.driverId ? await this.driverInfo.getUserPhone(trip.driverId) : null;
      return {
        id: trip.id, publicNo: trip.publicNo, type: 'TAXI', status: trip.status,
        createdAt: trip.createdAt, updatedAt: trip.updatedAt,
        customer: { id: trip.customerId, name: customer?.fullName ?? null, phone: customer?.phone ?? null },
        driver: trip.driverId
          ? { id: trip.driverId, name: driver?.fullName ?? null, phone: driverPhone, car: driver?.carName ?? null, plate: driver?.plateNumber ?? null }
          : null,
        pickup: trip.pickup,
        destination: trip.destination ?? null,
        metered: trip.metered,
        distanceKm: trip.distanceKm,
        actualDistanceKm: trip.actualDistanceKm ?? null,
        pickupDistanceKm: trip.pickupDistanceKm,
        pickupSurcharge: trip.pickupSurcharge,
        waitMinutes: trip.waitMinutes,
        fare: trip.fare,
        commission: trip.commission,
        driverEarning: trip.driverEarning,
        paymentType: trip.paymentType,
        rating: trip.rating ?? null,
        ratingComment: trip.ratingComment ?? null,
        statusHistory: await this.enrichHistory(trip.statusHistory),
      };
    }

    const parcel = await this.parcel.adminGetById(id);
    if (!parcel) throw new NotFoundException('Dostavka topilmadi');
    const [customer, driver] = await Promise.all([
      this.driverInfo.getUserInfo(parcel.customerId),
      parcel.driverId ? this.driverInfo.getPublic(parcel.driverId) : null,
    ]);
    const driverPhone = parcel.driverId ? await this.driverInfo.getUserPhone(parcel.driverId) : null;
    return {
      id: parcel.id, publicNo: parcel.publicNo, type: 'PARCEL', status: parcel.status,
      createdAt: parcel.createdAt, updatedAt: parcel.updatedAt,
      customer: { id: parcel.customerId, name: customer?.fullName ?? null, phone: customer?.phone ?? null },
      driver: parcel.driverId
        ? { id: parcel.driverId, name: driver?.fullName ?? null, phone: driverPhone, car: driver?.carName ?? null, plate: driver?.plateNumber ?? null }
        : null,
      pickup: parcel.pickup,
      destination: parcel.destination,
      size: parcel.size,
      recipientName: parcel.recipientName,
      recipientPhone: parcel.recipientPhone,
      note: parcel.note ?? null,
      distanceKm: parcel.distanceKm,
      actualDistanceKm: parcel.actualDistanceKm ?? null,
      fare: parcel.fare,
      commission: parcel.commission,
      driverEarning: parcel.driverEarning,
      paymentType: parcel.paymentType,
      rating: parcel.rating ?? null,
      ratingComment: parcel.ratingComment ?? null,
      statusHistory: await this.enrichHistory(parcel.statusHistory),
    };
  }

  /** statusHistory'dagi har bir haydovchi ID'sini ism/telefonga aylantiradi (jonli). */
  private async enrichHistory(
    history: { status: string; at: string; by?: string; driverId?: string; reason?: string }[],
  ) {
    const ids = Array.from(
      new Set((history ?? []).map((h) => h.driverId).filter((v): v is string => !!v)),
    );
    const infos = await Promise.all(ids.map((did) => this.driverInfo.getPublic(did)));
    const map = new Map(ids.map((did, i) => [did, infos[i]]));
    return (history ?? []).map((h) => ({
      ...h,
      driverName: h.driverId ? map.get(h.driverId)?.fullName ?? null : undefined,
    }));
  }

  // ---------- Kuryer (courier) ----------
  // TODO(driver auth): driverId JWT (driver roli) sub'idan olinadi.

  async listAvailableForDelivery() {
    return this.withRestaurant(await this.repo.findAvailableForDelivery());
  }

  async listDriverOrders(driverId: string) {
    return this.withRestaurant(await this.repo.findByDriver(driverId));
  }

  /**
   * Servislararo: haydovchining o'ziga tegishli buyurtmasini publicNo bo'yicha
   * topadi (3 vertikaldan) — services/support AI shikoyat funksiyasi uchun
   * (haydovchi aytgan buyurtma raqamidan mijozni aniqlash). Faqat shu
   * haydovchining JORIY buyurtmalari orasidan qidiradi (xavfsiz — boshqa
   * haydovchi ma'lumotiga kirish yo'q).
   */
  async lookupByDriverAndPublicNo(
    driverUserId: string,
    publicNo: number,
  ): Promise<{ type: 'FOOD' | 'TAXI' | 'PARCEL'; customerId: string } | null> {
    const foodMatch = await this.repo.findByDriverAndPublicNo(driverUserId, publicNo);
    if (foodMatch) return { type: 'FOOD', customerId: foodMatch.customerId };

    const tripMatch = await this.taxi.findByDriverAndPublicNo(driverUserId, publicNo);
    if (tripMatch) return { type: 'TAXI', customerId: tripMatch.customerId };

    const parcelMatch = await this.parcel.findByDriverAndPublicNo(driverUserId, publicNo);
    if (parcelMatch) return { type: 'PARCEL', customerId: parcelMatch.customerId };

    return null;
  }

  /** Haydovchi uchun bitta ovqat buyurtmasi — oshxona joylashuvi + mijoz raqami. */
  async getDriverOrderLive(id: string, driverId: string) {
    const order = await this.requireDriverOrder(id, driverId);
    const [dir, customerPhone] = await Promise.all([
      this.restaurant.getRestaurantDirectory(),
      this.driverInfo.getUserPhone(order.customerId),
    ]);
    return {
      ...order,
      restaurant: dir.get(order.restaurantId) ?? null,
      customerPhone,
    };
  }

  /**
   * Buyurtmalarni oshxona joylashuvi bilan boyitadi (kuryer navigatsiyasi —
   * olib ketish nuqtasi). Bitta katalog so'rovi; xato bo'lsa restaurant=null.
   */
  private async withRestaurant(orders: Order[]) {
    if (orders.length === 0) return [];
    const directory = await this.restaurant.getRestaurantDirectory();
    return orders.map((o) => ({
      ...o,
      restaurant: directory.get(o.restaurantId) ?? null,
    }));
  }

  /** Haydovchi daromadi — yetkazilgan buyurtmalar bo'yicha. */
  /** Haydovchi ovqat yetkazish daromadi (EarningsSummary). */
  async driverEarnings(driverId: string): Promise<EarningsSummary> {
    const orders = await this.repo.findByDriver(driverId);
    return summarizeEarnings(
      orders,
      (o) => o.status === 'DELIVERED',
      (o) => ['ASSIGNED', 'PICKED_UP'].includes(o.status),
      (o) => o.courierEarning,
      (o) => o.updatedAt,
    );
  }

  /**
   * Haydovchi statistikasi (Bugun ekrani) — kun/hafta/oy bo'yicha bajarilgan
   * buyurtmalar (3 vertikal), kunlik grafik nuqtalari va ro'yxat.
   */
  async driverStats(driverId: string, period: ReportPeriod) {
    const start = periodStart(period).getTime();
    const [foodOrders, taxiTrips, parcels] = await Promise.all([
      this.repo.findByDriver(driverId),
      this.taxi.listDriverTrips(driverId),
      this.parcel.listDriverParcels(driverId),
    ]);

    type Done = {
      type: 'food' | 'taxi' | 'parcel';
      amount: number;
      earning: number;
      createdAt: string;
    };
    const done: Done[] = [];
    for (const o of foodOrders) {
      if (o.status === 'DELIVERED') {
        done.push({ type: 'food', amount: o.total, earning: o.courierEarning, createdAt: o.createdAt });
      }
    }
    for (const t of taxiTrips) {
      if (t.status === 'COMPLETED') {
        done.push({ type: 'taxi', amount: t.fare, earning: t.driverEarning, createdAt: t.createdAt });
      }
    }
    for (const p of parcels) {
      if (p.status === 'DELIVERED') {
        done.push({ type: 'parcel', amount: p.fare, earning: p.driverEarning, createdAt: p.createdAt });
      }
    }

    const inPeriod = done
      .filter((d) => new Date(d.createdAt).getTime() >= start)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    const totalEarning = inPeriod.reduce((s, d) => s + d.earning, 0);

    // Kunlik grafik nuqtalari (start..bugun)
    const dayMap = new Map<string, { count: number; earning: number }>();
    for (const d of inPeriod) {
      const key = d.createdAt.slice(0, 10);
      const cur = dayMap.get(key) ?? { count: 0, earning: 0 };
      cur.count += 1;
      cur.earning += d.earning;
      dayMap.set(key, cur);
    }
    const daily: { date: string; count: number; earning: number }[] = [];
    const dayMs = 86400000;
    for (let t = new Date(start).setHours(0, 0, 0, 0); t <= Date.now(); t += dayMs) {
      const key = new Date(t).toISOString().slice(0, 10);
      const v = dayMap.get(key) ?? { count: 0, earning: 0 };
      daily.push({ date: key, count: v.count, earning: v.earning });
    }

    return {
      period,
      totalCount: inPeriod.length,
      totalEarning,
      daily,
      orders: inPeriod.slice(0, 50),
    };
  }

  /**
   * Haydovchi ovqat buyurtmasini qabul qiladi (yaratishdayoq taklifdan) —
   * PENDING/ACCEPTED/PREPARING da mumkin. driverId qo'yiladi; oshxona ham
   * qabul qilgan bo'lsa buyurtma tasdiqlanadi (maybeConfirm).
   */
  async acceptDelivery(id: string, driverId: string): Promise<Order> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.driverId && order.driverId !== driverId) {
      throw new BadRequestException('Buyurtma allaqachon boshqa haydovchiga tegishli');
    }
    if (!['PENDING', 'ACCEPTED', 'PREPARING'].includes(order.status)) {
      throw new BadRequestException('Buyurtma qabul qilishga tayyor emas');
    }
    const withDriver = await this.repo.setDriverAccepted(id, driverId);
    this.dispatch.clear(id); // dispatchdan olib tashlaymiz
    return this.maybeConfirm(withDriver);
  }

  /** Oshxonadan oldi (READY -> PICKED_UP) — oshxona tayyor deb belgilagach. */
  async pickup(id: string, driverId: string): Promise<Order> {
    const order = await this.requireDriverOrder(id, driverId);
    if (!['READY', 'ASSIGNED'].includes(order.status)) {
      throw new BadRequestException('Buyurtma hali tayyor emas');
    }
    const updated = await this.repo.updateStatus(id, 'PICKED_UP');
    await this.notifyOrderStatus(updated);
    return updated;
  }

  /**
   * Haydovchi buyurtmadan voz kechadi (olib ketishdan OLDIN) — driver
   * tozalanadi, buyurtma boshqa haydovchilarga qayta taklif qilinadi.
   * Mijoz uchun bu bekor emas: jarayon davom etadi (yangi kuryer qidiriladi).
   * Sabab majburiy — balansdan jarima yechiladi; mijoz aybi bo'lsa
   * sezdirmasdan qaytariladi.
   */
  async driverCancelFood(
    id: string,
    driverId: string,
    reason: DriverCancelReason,
    note?: string,
  ): Promise<{ ok: true }> {
    if (!isDriverCancelReason(reason)) {
      throw new BadRequestException("Bekor qilish sababini tanlang");
    }
    const order = await this.requireDriverOrder(id, driverId);
    if (!['PENDING', 'ACCEPTED', 'PREPARING', 'READY'].includes(order.status)) {
      throw new BadRequestException(
        "Olib bo'lingan buyurtmadan voz kechib bo'lmaydi",
      );
    }
    const cleared = await this.repo.clearDriver(id, reason, note);
    // Qayta dispatch: eng yaqin haydovchi -> keyingisi -> pool.
    await this.offerToDrivers(cleared);
    try {
      const t = await this.tariff.getTariff();
      const penalty = t.driverCancelPenalty;
      if (penalty > 0) {
        await this.driverInfo.charge(driverId, penalty, `Buyurtma #${order.publicNo} bekor qilindi`);
        if (CANCEL_REASON_CUSTOMER_FAULT[reason]) {
          await this.driverInfo.silentRefund(driverId, penalty, `Tuzatish: Buyurtma #${order.publicNo}`);
        }
      }
    } catch (e) {
      this.logger.warn(`Bekor qilish jarimasi xatosi: ${(e as Error).message}`);
    }
    await this.driverInfo.recordCancellation(driverId);
    return { ok: true };
  }

  /** Mijozga yetkazdi (PICKED_UP -> DELIVERED). Xizmat haqi balansdan yechiladi. */
  async delivered(id: string, driverId: string): Promise<Order> {
    const order = await this.requireDriverOrder(id, driverId);
    if (order.status !== 'PICKED_UP') {
      throw new BadRequestException('Buyurtma yetkazish holatida emas');
    }
    const updated = await this.repo.updateStatus(id, 'DELIVERED');
    await this.notifyOrderStatus(updated);
    // Xizmat haqi (platforma daromadi) haydovchi prepaid balansidan (naqd oqim).
    try {
      await this.driverInfo.charge(
        driverId,
        updated.serviceFee,
        `Ovqat #${updated.publicNo}`,
      );
    } catch (e) {
      this.logger.warn(`Xizmat haqi yechishda xato: ${(e as Error).message}`);
    }
    await this.driverInfo.recordCompletion(driverId);
    return updated;
  }

  private async requireDriverOrder(id: string, driverId: string): Promise<Order> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.driverId !== driverId) {
      throw new ForbiddenException('Bu buyurtma sizga biriktirilmagan');
    }
    return order;
  }

  /** Holatni faqat ruxsat etilgan o'tish bo'yicha o'zgartiradi. */
  private async transition(
    id: string,
    from: Order['status'][],
    to: Order['status'],
  ): Promise<Order> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (!from.includes(order.status)) {
      throw new BadRequestException(
        `Holatni '${order.status}' dan '${to}' ga o'zgartirib bo'lmaydi`,
      );
    }
    const updated = await this.repo.updateStatus(id, to);
    await this.notifyOrderStatus(updated);
    return updated;
  }
}
