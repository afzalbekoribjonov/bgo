import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PromoService } from '../promo/promo.service';
import { RestaurantClient } from '../restaurant-client/restaurant.client';
import { TariffService } from '../tariff/tariff.service';
import { EarningsSummary, summarizeEarnings } from '../common/earnings';
import { CreateOrderDto } from './dto/create-order.dto';
import { Order, OrderItem, OrderStatus } from './entities';
import { OrderRepository } from './order.repository';

export type ReportPeriod = 'today' | 'week' | 'month';

/** Yakuniy (muvaffaqiyatli yopilgan) holatlar — aylanma/foyda shulardan. */
const TERMINAL_STATUSES: OrderStatus[] = ['DELIVERED', 'COMPLETED'];
/** Bekor qilingan holatlar. */
const CANCELLED_STATUSES: OrderStatus[] = ['CANCELLED', 'FAILED'];

/** Mahalliy (TZ) sana kaliti YYYY-MM-DD. */
function localDateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

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
export class OrdersService {
  constructor(
    private readonly repo: OrderRepository,
    private readonly restaurant: RestaurantClient,
    private readonly tariff: TariffService,
    private readonly promo: PromoService,
  ) {}

  /** Buyurtma yaratish — narx/komissiya SERVER tomonda (katalog + tarif). */
  async create(customerId: string, dto: CreateOrderDto, locale: string) {
    const menu = await this.restaurant.getMenuItems(dto.restaurantId, locale);

    const items: OrderItem[] = dto.items.map((cartItem) => {
      const catalogItem = menu.get(cartItem.menuItemId);
      if (!catalogItem) {
        throw new BadRequestException(
          `Taom topilmadi: ${cartItem.menuItemId}`,
        );
      }
      if (!catalogItem.isAvailable) {
        throw new BadRequestException(`Taom mavjud emas: ${catalogItem.name}`);
      }
      return {
        menuItemId: cartItem.menuItemId,
        nameSnapshot: catalogItem.name,
        priceSnapshot: catalogItem.price,
        qty: cartItem.qty,
        lineTotal: catalogItem.price * cartItem.qty,
      };
    });

    const itemsTotal = items.reduce((sum, i) => sum + i.lineTotal, 0);
    const tariff = await this.tariff.getTariff();
    const deliveryFee = tariff.deliveryFee;
    // Komissiya = bizning ulush (oshxona taomlar summasidan)
    const commission = Math.round(
      (itemsTotal * tariff.foodCommissionPercent) / 100,
    );
    // Haydovchi ulushi — yetkazish narxidan
    const courierEarning = Math.round(
      (deliveryFee * tariff.courierSharePercent) / 100,
    );

    // Promokod (ixtiyoriy) — chegirma taomlar summasidan
    let discount = 0;
    let promoCode: string | undefined;
    if (dto.promoCode) {
      const applied = await this.promo.apply(dto.promoCode, itemsTotal);
      discount = applied.discount;
      promoCode = applied.code;
    }

    const total = itemsTotal + deliveryFee - discount;

    const order = await this.repo.create({
      customerId,
      type: dto.type,
      restaurantId: dto.restaurantId,
      items,
      itemsTotal,
      deliveryFee,
      commission,
      courierEarning,
      promoCode,
      discount,
      total,
      paymentType: dto.paymentType,
      address: dto.address,
    });
    if (promoCode) await this.promo.incrementUsage(promoCode);
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
    return this.repo.updateStatus(id, 'CANCELLED');
  }

  // ---------- Oshxona (kitchen) ----------
  // TODO(restaurant auth): restaurant roli JWT + egalik tekshiruvi.

  listForRestaurant(restaurantId: string) {
    return this.repo.findByRestaurant(restaurantId);
  }

  /** Buyurtmaning oshxonasi (egalik tekshiruvi uchun). */
  async restaurantIdOf(id: string): Promise<string> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    return order.restaurantId;
  }

  acceptByRestaurant(id: string) {
    return this.transition(id, ['PENDING'], 'ACCEPTED');
  }

  startPreparing(id: string) {
    return this.transition(id, ['ACCEPTED'], 'PREPARING');
  }

  markReady(id: string) {
    return this.transition(id, ['ACCEPTED', 'PREPARING'], 'READY');
  }

  rejectByRestaurant(id: string) {
    return this.transition(id, ['PENDING', 'ACCEPTED'], 'CANCELLED');
  }

  // ---------- Admin / hisobot ----------
  // TODO(admin auth): admin roli JWT. Hozir ochiq (dev).

  /** Buyurtma foydasi = komissiya + (yetkazish − kuryer ulushi) − chegirma. */
  private orderProfit(o: Order): number {
    return o.commission + (o.deliveryFee - o.courierEarning) - o.discount;
  }

  async adminStats() {
    const orders = await this.repo.findAll();
    const closed = [...TERMINAL_STATUSES, ...CANCELLED_STATUSES];

    const byStatus: Record<string, number> = {};
    let revenue = 0;
    let profit = 0;
    let today = 0;
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    for (const o of orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
      if (TERMINAL_STATUSES.includes(o.status)) {
        revenue += o.total;
        profit += this.orderProfit(o);
      }
      if (new Date(o.createdAt) >= startOfDay) today += 1;
    }

    return {
      totalOrders: orders.length,
      activeOrders: orders.filter((o) => !closed.includes(o.status)).length,
      todayOrders: today,
      revenue, // yetkazilgan buyurtmalar aylanmasi (so'm)
      profit, // bizning foyda (komissiya), so'm
      byStatus,
    };
  }

  /** Davr hisoboti (bugun/hafta/oy) — xulosa + kunlik time-series. */
  async adminReport(period: ReportPeriod) {
    const orders = await this.repo.findAll();
    const days = period === 'today' ? 1 : period === 'week' ? 7 : 30;

    const from = new Date();
    from.setHours(0, 0, 0, 0);
    from.setDate(from.getDate() - (days - 1));
    const fromTs = from.getTime();

    // Kunlik chelaklarni oldindan to'ldiramiz (bo'sh kunlar ham ko'rinadi)
    const daily = new Map<
      string,
      { date: string; orders: number; revenue: number; profit: number }
    >();
    for (let i = 0; i < days; i++) {
      const d = new Date(from);
      d.setDate(from.getDate() + i);
      const key = localDateKey(d);
      daily.set(key, { date: key, orders: 0, revenue: 0, profit: 0 });
    }

    let totalOrders = 0;
    let delivered = 0;
    let cancelled = 0;
    let revenue = 0;
    let profit = 0;

    for (const o of orders) {
      if (new Date(o.createdAt).getTime() < fromTs) continue;
      totalOrders += 1;
      const bucket = daily.get(localDateKey(new Date(o.createdAt)));
      if (bucket) bucket.orders += 1;
      if (TERMINAL_STATUSES.includes(o.status)) {
        delivered += 1;
        const p = this.orderProfit(o);
        revenue += o.total;
        profit += p;
        if (bucket) {
          bucket.revenue += o.total;
          bucket.profit += p;
        }
      } else if (CANCELLED_STATUSES.includes(o.status)) {
        cancelled += 1;
      }
    }

    return {
      period,
      from: from.toISOString(),
      to: new Date().toISOString(),
      summary: {
        totalOrders,
        delivered,
        cancelled,
        revenue,
        profit,
        avgOrder: delivered > 0 ? Math.round(revenue / delivered) : 0,
      },
      daily: Array.from(daily.values()),
    };
  }

  async adminListOrders(filter: {
    status?: string;
    type?: string;
    from?: string;
    to?: string;
    q?: string;
    sort?: 'createdAt' | 'total';
    order?: 'asc' | 'desc';
  }) {
    const fromTs = parseDayBoundary(filter.from, 'start');
    const toTs = parseDayBoundary(filter.to, 'end');
    const q = filter.q?.trim().toLowerCase();

    const filtered = (await this.repo.findAll()).filter((o) => {
      if (filter.status && o.status !== filter.status) return false;
      if (filter.type && o.type !== filter.type) return false;
      const ts = new Date(o.createdAt).getTime();
      if (fromTs !== undefined && ts < fromTs) return false;
      if (toTs !== undefined && ts > toTs) return false;
      if (q) {
        const hay = `${o.publicNo} ${o.address?.text ?? ''}`.toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });

    const sortKey = filter.sort ?? 'createdAt';
    const dir = filter.order === 'asc' ? 1 : -1;
    filtered.sort((a, b) => {
      const av = sortKey === 'total' ? a.total : new Date(a.createdAt).getTime();
      const bv = sortKey === 'total' ? b.total : new Date(b.createdAt).getTime();
      return (av - bv) * dir;
    });
    return filtered;
  }

  // ---------- Kuryer (courier) ----------
  // TODO(driver auth): driverId JWT (driver roli) sub'idan olinadi.

  listAvailableForDelivery() {
    return this.repo.findAvailableForDelivery();
  }

  listDriverOrders(driverId: string) {
    return this.repo.findByDriver(driverId);
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
      (o) => o.createdAt,
    );
  }

  /** Haydovchi yetkazishni qabul qiladi (READY -> ASSIGNED). */
  async acceptDelivery(id: string, driverId: string): Promise<Order> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.status !== 'READY') {
      throw new BadRequestException('Buyurtma yetkazishga tayyor emas');
    }
    if (order.driverId) {
      throw new BadRequestException('Buyurtma allaqachon haydovchiga biriktirilgan');
    }
    return this.repo.assignDriver(id, driverId);
  }

  /** Oshxonadan oldi (ASSIGNED -> PICKED_UP). */
  async pickup(id: string, driverId: string): Promise<Order> {
    const order = await this.requireDriverOrder(id, driverId);
    if (order.status !== 'ASSIGNED') {
      throw new BadRequestException('Buyurtma olishga tayyor emas');
    }
    return this.repo.updateStatus(id, 'PICKED_UP');
  }

  /** Mijozga yetkazdi (PICKED_UP -> DELIVERED). */
  async delivered(id: string, driverId: string): Promise<Order> {
    const order = await this.requireDriverOrder(id, driverId);
    if (order.status !== 'PICKED_UP') {
      throw new BadRequestException('Buyurtma yetkazish holatida emas');
    }
    return this.repo.updateStatus(id, 'DELIVERED');
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
    return this.repo.updateStatus(id, to);
  }
}
