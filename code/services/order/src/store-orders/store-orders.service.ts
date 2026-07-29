import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { DispatchService } from '../orders/dispatch.service';
import { DriverInfoClient, UserBasicInfo } from '../driver-client/driver-info.client';
import { EarningsSummary, summarizeEarnings } from '../common/earnings';
import { GeoPoint, haversineKm } from '../common/geo';
import { roundFare } from '../common/money';
import { MarketClient } from '../market-client/market.client';
import {
  buildVerticalReport,
  buildVerticalReportRange,
  buildVerticalStats,
  ReportPeriod,
} from '../common/reporting';
import { NotificationClient } from '../notification-client/notification.client';
import { TariffService } from '../tariff/tariff.service';
import { DriverLocation } from '../tracking/entities';
import { DriverLocationService } from '../tracking/driver-location.service';
import { CreateStoreOrderDto } from './dto/create-store-order.dto';
import {
  AdminStoreOrderView,
  StoreOrder,
  StoreOrderItem,
  StoreOrderLive,
  StoreOrderStatus,
} from './entities';
import { StoreOrderRepository } from './store-order.repository';

const ACTIVE_DELIVERY_STATUSES = ['ACCEPTED', 'ARRIVED', 'PICKED_UP', 'IN_TRANSIT'];

/** Beshariq Market buyurtmasi — narx SERVER tomonda (market katalogi + tarif). */
@Injectable()
export class StoreOrdersService implements OnModuleInit {
  private readonly logger = new Logger(StoreOrdersService.name);

  constructor(
    private readonly repo: StoreOrderRepository,
    private readonly tariff: TariffService,
    private readonly notifications: NotificationClient,
    private readonly dispatch: DispatchService,
    private readonly driverInfo: DriverInfoClient,
    private readonly driverLocations: DriverLocationService,
    private readonly market: MarketClient,
  ) {}

  /** Dispatch fail-callback (kuryer topilmasa) + restart tiklanishi. */
  onModuleInit(): void {
    this.dispatch.setFailHandler((orderId, vertical) => {
      if (vertical === 'market') {
        this.failOrder(orderId).catch(() => undefined);
      }
    });
    setTimeout(() => {
      this.recoverPending().catch((e) =>
        this.logger.warn(`Store dispatch tiklanishi xatosi: ${(e as Error).message}`),
      );
    }, 2000);
  }

  /** Pool'da kuryer topilmadi — buyurtma bekor, zaxira qaytariladi, mijozga xabar. */
  private async failOrder(orderId: string): Promise<void> {
    const order = await this.repo.findById(orderId);
    if (!order || order.status !== 'PENDING') return;
    const cancelled = await this.repo.updateStatus(orderId, 'CANCELLED', {
      by: 'system',
      reason: 'Kuryer topilmadi',
    });
    await this.releaseOrderStock(order);
    await this.notifyCustomer(cancelled, 'Hozircha kuryer topilmadi. Buyurtma bekor qilindi');
  }

  private async recoverPending(): Promise<void> {
    const pending = await this.repo.findAvailable();
    if (pending.length === 0) return;
    this.logger.log(`Dispatch tiklanishi: ${pending.length} ta Market buyurtma qayta yuborilmoqda`);
    await Promise.all(pending.map((o) => this.offerOrder(o)));
  }

  // ---------- Narx ----------

  private async estimateDeliveryFee(
    pickup: GeoPoint,
    destination: GeoPoint,
  ): Promise<{ distanceKm: number; deliveryFee: number }> {
    const t = await this.tariff.getTariff();
    const distanceKm = Math.round(haversineKm(pickup, destination) * 100) / 100;
    const base = Math.max(t.parcelMinFare, t.parcelBaseFare + Math.round(t.parcelPerKm * distanceKm));
    return { distanceKm, deliveryFee: roundFare(base) };
  }

  // ---------- Yaratish ----------

  /**
   * O'lcham tekshiruvi: mahsulotda o'lchamlar bo'lsa mijoz bittasini tanlashi
   * shart va u katalogdagi ro'yxatda bo'lishi kerak (mijoz yuborgan matnga
   * ishonilmaydi — katalogdagi asl yozuv snapshot sifatida saqlanadi).
   */
  private resolveSize(
    productName: string,
    available: string[],
    picked?: string,
  ): string | undefined {
    if (available.length === 0) return undefined;
    const chosen = picked?.trim();
    if (!chosen) {
      throw new BadRequestException(`"${productName}" uchun o'lcham tanlang`);
    }
    const match = available.find((s) => s.toLowerCase() === chosen.toLowerCase());
    if (!match) {
      throw new BadRequestException(
        `"${productName}" uchun "${chosen}" o'lchami mavjud emas`,
      );
    }
    return match;
  }

  async create(customerId: string, dto: CreateStoreOrderDto): Promise<StoreOrder> {
    const pickupLocation = await this.market.getPickupLocation(dto.pickupLocationId);

    // Har item uchun narx/nom SERVER tomonda (market katalogidan) — mijoz
    // yuborgan narxga ishonilmaydi. Zaxira ketma-ket band qilinadi; birortasi
    // yetishmasa avvalgilari qaytariladi (all-or-nothing).
    const items: StoreOrderItem[] = [];
    const reserved: { productId: string; qty: number }[] = [];
    try {
      for (const line of dto.items) {
        const product = await this.market.getProduct(line.productId);
        const size = this.resolveSize(product.name, product.sizes ?? [], line.size);
        await this.market.reserveStock(line.productId, line.qty);
        reserved.push({ productId: line.productId, qty: line.qty });
        items.push({
          productId: product.id,
          nameSnapshot: product.name,
          priceSnapshot: product.price,
          qty: line.qty,
          lineTotal: product.price * line.qty,
          ...(size ? { size } : {}),
        });
      }
    } catch (err) {
      await Promise.all(
        reserved.map((r) => this.market.releaseStock(r.productId, r.qty)),
      );
      throw err;
    }

    const itemsTotal = items.reduce((sum, it) => sum + it.lineTotal, 0);
    let deliveryFee = 0;
    if (dto.deliveryMethod === 'DELIVERY') {
      if (!dto.address) {
        throw new BadRequestException("Yetkazish uchun manzil ko'rsatilishi shart");
      }
      const est = await this.estimateDeliveryFee(
        { text: pickupLocation.name, lat: pickupLocation.lat, lng: pickupLocation.lng },
        dto.address,
      );
      deliveryFee = est.deliveryFee;
    }
    const total = itemsTotal + deliveryFee;

    const order = await this.repo.create({
      customerId,
      pickupLocationId: dto.pickupLocationId,
      deliveryMethod: dto.deliveryMethod,
      address: dto.deliveryMethod === 'DELIVERY' ? dto.address : undefined,
      items,
      itemsTotal,
      deliveryFee,
      courierEarning: deliveryFee, // komissiyasiz — haydovchi to'liq oladi
      total,
    });

    if (dto.deliveryMethod === 'DELIVERY') {
      this.offerOrder(order).catch((err) =>
        this.logger.warn(`Market dispatch xatosi: ${(err as Error).message}`),
      );
    } else {
      // Olib ketish — tayyorgarlik shart emas (ombordan), darhol tayyor.
      await this.repo.updateStatus(order.id, 'READY_FOR_PICKUP', { by: 'system' });
    }
    return (await this.repo.findById(order.id)) ?? order;
  }

  private async offerOrder(order: StoreOrder): Promise<void> {
    const pickupLocation = await this.market.getPickupLocation(order.pickupLocationId);
    await this.dispatch.offer({
      orderId: order.id,
      vertical: 'market',
      pickupLat: pickupLocation.lat,
      pickupLng: pickupLocation.lng,
      pickupName: pickupLocation.name,
      dropoffLat: order.address?.lat ?? null,
      dropoffLng: order.address?.lng ?? null,
      dropoffText: order.address?.text ?? null,
      amount: order.total,
      earning: order.courierEarning,
    });
  }

  // ---------- Mijoz ----------

  async listMine(customerId: string): Promise<StoreOrder[]> {
    return this.repo.findByCustomer(customerId);
  }

  async getOwned(customerId: string, id: string): Promise<StoreOrder> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.customerId !== customerId) {
      throw new ForbiddenException('Bu buyurtma sizga tegishli emas');
    }
    return order;
  }

  async getOwnedLive(customerId: string, id: string): Promise<StoreOrderLive> {
    return this.toLive(await this.getOwned(customerId, id));
  }

  async toLive(order: StoreOrder): Promise<StoreOrderLive> {
    let driverName: string | null | undefined;
    let driverCar: string | null | undefined;
    let driverPlate: string | null | undefined;
    let driverPhone: string | null | undefined;
    let customerPhone: string | null | undefined;
    if (order.driverId && ACTIVE_DELIVERY_STATUSES.includes(order.status)) {
      const [info, dPhone, cPhone] = await Promise.all([
        this.driverInfo.getPublic(order.driverId),
        this.driverInfo.getUserPhone(order.driverId),
        this.driverInfo.getUserPhone(order.customerId),
      ]);
      if (info) {
        driverName = info.fullName;
        driverCar = info.carName ?? null;
        driverPlate = info.plateNumber ?? null;
      }
      driverPhone = dPhone;
      customerPhone = cPhone;
    }
    let pickupLocationName: string | null | undefined;
    let pickupLat: number | undefined;
    let pickupLng: number | undefined;
    try {
      const loc = await this.market.getPickupLocation(order.pickupLocationId);
      pickupLocationName = loc.name;
      pickupLat = loc.lat;
      pickupLng = loc.lng;
    } catch {
      pickupLocationName = null;
    }
    return {
      ...order,
      pickupLocationName,
      pickupLat,
      pickupLng,
      driverName,
      driverCar,
      driverPlate,
      driverPhone,
      customerPhone,
    };
  }

  /** Biriktirilgan haydovchining jonli joylashuvi (xaritada ko'rsatish uchun). */
  async driverLocationForOrder(customerId: string, id: string): Promise<DriverLocation | null> {
    const order = await this.getOwned(customerId, id);
    if (!order.driverId) return null;
    return this.driverLocations.get(order.driverId);
  }

  private async releaseOrderStock(order: StoreOrder): Promise<void> {
    await Promise.all(
      order.items.map((it) => this.market.releaseStock(it.productId, it.qty)),
    );
  }

  /** Mijoz bekor qiladi — hali yetkazilmagan/olib ketilmagan bosqichda. */
  async cancel(customerId: string, id: string): Promise<StoreOrder> {
    const order = await this.getOwned(customerId, id);
    const cancellable = ['PENDING', 'ACCEPTED', 'ARRIVED', 'READY_FOR_PICKUP'];
    if (!cancellable.includes(order.status)) {
      throw new BadRequestException("Buyurtmani bu bosqichda bekor qilib bo'lmaydi");
    }
    this.dispatch.clear(id);
    const cancelled = await this.repo.updateStatus(id, 'CANCELLED', {
      by: 'customer',
      driverId: order.driverId,
    });
    await this.releaseOrderStock(order);
    if (order.driverId) {
      await this.notifications.notify(
        order.driverId,
        'Market',
        'Mijoz buyurtmani bekor qildi',
        { type: 'store', id, status: 'CANCELLED', cancelledBy: 'customer' },
      );
    }
    return cancelled;
  }

  async rate(customerId: string, id: string, rating: number, comment?: string): Promise<StoreOrder> {
    const order = await this.getOwned(customerId, id);
    if (!['DELIVERED', 'COMPLETED'].includes(order.status)) {
      throw new BadRequestException('Faqat yakunlangan buyurtmani baholash mumkin');
    }
    if (rating < 1 || rating > 5) {
      throw new BadRequestException("Baho 1-5 oralig'ida bo'lishi kerak");
    }
    return this.repo.setRating(id, rating, comment);
  }

  // ---------- Haydovchi (faqat DELIVERY) ----------

  listAvailable() {
    return this.repo.findAvailable();
  }

  listDriverOrders(driverId: string) {
    return this.repo.findByDriver(driverId);
  }

  async listActiveDriverOrders(driverId: string): Promise<StoreOrderLive[]> {
    const orders = await this.repo.findByDriver(driverId);
    const active = orders.filter((o) => ACTIVE_DELIVERY_STATUSES.includes(o.status));
    return Promise.all(active.map((o) => this.toLive(o)));
  }

  async liveForDriver(driverId: string, id: string): Promise<StoreOrderLive> {
    return this.toLive(await this.requireDriverOrder(id, driverId));
  }

  private async requireDriverOrder(id: string, driverId: string): Promise<StoreOrder> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.driverId !== driverId) {
      throw new ForbiddenException('Bu buyurtma sizga biriktirilmagan');
    }
    return order;
  }

  async accept(id: string, driverId: string): Promise<StoreOrder> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.status !== 'PENDING') {
      throw new BadRequestException('Buyurtma qabul qilishga tayyor emas');
    }
    if (order.driverId) {
      throw new BadRequestException('Buyurtma allaqachon biriktirilgan');
    }
    const updated = await this.repo.assignDriver(id, driverId);
    this.dispatch.clear(id);
    await this.notifyCustomer(updated, 'Haydovchi buyurtmani qabul qildi');
    return updated;
  }

  async arrive(id: string, driverId: string): Promise<StoreOrder> {
    const order = await this.requireDriverOrder(id, driverId);
    if (order.status !== 'ACCEPTED') {
      throw new BadRequestException('Buyurtma bu bosqichda emas');
    }
    const updated = await this.repo.updateStatus(id, 'ARRIVED');
    await this.notifyCustomer(updated, "Haydovchi olib ketish nuqtasiga yetib keldi");
    return updated;
  }

  async pickup(id: string, driverId: string): Promise<StoreOrder> {
    const order = await this.requireDriverOrder(id, driverId);
    if (!['ARRIVED', 'ACCEPTED'].includes(order.status)) {
      throw new BadRequestException('Buyurtma olishga tayyor emas');
    }
    const updated = await this.repo.updateStatus(id, 'PICKED_UP');
    await this.notifyCustomer(updated, 'Haydovchi buyurtmani oldi');
    return updated;
  }

  async startTransit(id: string, driverId: string): Promise<StoreOrder> {
    const order = await this.requireDriverOrder(id, driverId);
    if (order.status !== 'PICKED_UP') {
      throw new BadRequestException("Buyurtma yo'lga chiqishga tayyor emas");
    }
    const updated = await this.repo.updateStatus(id, 'IN_TRANSIT');
    await this.notifyCustomer(updated, "Haydovchi sizga yo'lda");
    return updated;
  }

  async delivered(id: string, driverId: string): Promise<StoreOrder> {
    const order = await this.requireDriverOrder(id, driverId);
    if (!['IN_TRANSIT', 'PICKED_UP'].includes(order.status)) {
      throw new BadRequestException('Buyurtma yetkazish holatida emas');
    }
    const updated = await this.repo.updateStatus(id, 'DELIVERED');
    await this.notifyCustomer(updated, `Buyurtma yetkazildi. To'lov: ${updated.total} so'm`);
    // Komissiyasiz — haydovchi balansidan hech narsa yechilmaydi (deliveryFee to'liq uniki).
    return updated;
  }

  /** Haydovchi bekor qiladi (ACCEPTED/ARRIVED) -> qayta dispatch. */
  async driverCancel(id: string, driverId: string): Promise<StoreOrder> {
    const order = await this.requireDriverOrder(id, driverId);
    if (!['ACCEPTED', 'ARRIVED'].includes(order.status)) {
      throw new BadRequestException("Bu bosqichda bekor qilib bo'lmaydi");
    }
    await this.notifications.notify(
      order.customerId,
      'Market',
      'Haydovchi voz kechdi. Boshqa haydovchi qidirilmoqda',
      { type: 'store', id, status: 'PENDING', cancelledBy: 'driver' },
    );
    const released = await this.repo.releaseToPending(id);
    this.offerOrder(released).catch((e) =>
      this.logger.warn(`Qayta taklif xatosi: ${(e as Error).message}`),
    );
    return released;
  }

  /** Haydovchi Market yetkazish daromadi (EarningsSummary). */
  async driverEarnings(driverId: string): Promise<EarningsSummary> {
    const orders = await this.repo.findByDriverForEarnings(driverId);
    return summarizeEarnings(
      orders,
      (o) => o.status === 'DELIVERED',
      (o) => ACTIVE_DELIVERY_STATUSES.includes(o.status),
      (o) => o.courierEarning,
      (o) => o.updatedAt,
    );
  }

  // ---------- Admin ----------

  /** PICKUP buyurtmani mijoz olib ketganda staff tomonidan yakunlanadi. */
  async adminCompletePickup(id: string): Promise<StoreOrder> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    if (order.deliveryMethod !== 'PICKUP') {
      throw new BadRequestException('Bu buyurtma olib ketish turida emas');
    }
    if (order.status !== 'READY_FOR_PICKUP') {
      throw new BadRequestException("Buyurtma hali olib ketishga tayyor emas");
    }
    return this.repo.updateStatus(id, 'COMPLETED', { by: 'admin' });
  }

  /**
   * Admin qo'lda holatni o'zgartiradi. Faqat mantiqan to'g'ri o'tishlarga ruxsat
   * (yakunlangan/bekor qilingan buyurtma qayta ochilmaydi). CANCELLED va PICKUP
   * COMPLETED mavjud mantiqqa yo'naltiriladi — zaxira qaytarish/tekshiruv saqlanadi.
   */
  async adminSetStatus(id: string, next: StoreOrderStatus): Promise<StoreOrder> {
    const order = await this.repo.findById(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');

    if (order.status === next) return order;

    if (['DELIVERED', 'COMPLETED', 'CANCELLED'].includes(order.status)) {
      throw new BadRequestException(
        'Yakunlangan yoki bekor qilingan buyurtma holatini o\'zgartirib bo\'lmaydi',
      );
    }

    if (next === 'CANCELLED') {
      const cancelled = await this.adminCancel(id);
      if (!cancelled) throw new NotFoundException('Buyurtma topilmadi');
      await this.notifyCustomer(cancelled, 'Buyurtmangiz bekor qilindi');
      return cancelled;
    }

    const allowed = this.allowedAdminTransitions(order);
    if (!allowed.includes(next)) {
      throw new BadRequestException(
        `Bu bosqichda "${next}" holatiga o'tib bo'lmaydi`,
      );
    }

    if (next === 'COMPLETED' && order.deliveryMethod === 'PICKUP') {
      const done = await this.adminCompletePickup(id);
      await this.notifyCustomer(done, 'Buyurtmangiz yakunlandi');
      return done;
    }

    const updated = await this.repo.updateStatus(id, next, { by: 'admin' });
    await this.notifyCustomer(updated, this.statusMessage(next));
    return updated;
  }

  /** Joriy holatdan admin o'tkaza oladigan holatlar (UI shu ro'yxatni ko'rsatadi). */
  allowedAdminTransitions(order: StoreOrder): StoreOrderStatus[] {
    if (['DELIVERED', 'COMPLETED', 'CANCELLED'].includes(order.status)) return [];
    if (order.deliveryMethod === 'PICKUP') {
      const map: Partial<Record<StoreOrderStatus, StoreOrderStatus[]>> = {
        PENDING: ['READY_FOR_PICKUP', 'CANCELLED'],
        READY_FOR_PICKUP: ['COMPLETED', 'CANCELLED'],
      };
      return map[order.status] ?? ['CANCELLED'];
    }
    const map: Partial<Record<StoreOrderStatus, StoreOrderStatus[]>> = {
      PENDING: ['CANCELLED'],
      ACCEPTED: ['ARRIVED', 'PICKED_UP', 'CANCELLED'],
      ARRIVED: ['PICKED_UP', 'CANCELLED'],
      PICKED_UP: ['IN_TRANSIT', 'DELIVERED', 'CANCELLED'],
      IN_TRANSIT: ['DELIVERED', 'CANCELLED'],
    };
    return map[order.status] ?? ['CANCELLED'];
  }

  private statusMessage(status: StoreOrderStatus): string {
    const map: Partial<Record<StoreOrderStatus, string>> = {
      READY_FOR_PICKUP: 'Buyurtmangiz olib ketishga tayyor',
      ARRIVED: 'Haydovchi olib ketish nuqtasiga yetib keldi',
      PICKED_UP: 'Buyurtmangiz olindi',
      IN_TRANSIT: "Buyurtmangiz yo'lda",
      DELIVERED: 'Buyurtmangiz yetkazildi',
      COMPLETED: 'Buyurtmangiz yakunlandi',
    };
    return map[status] ?? 'Buyurtma holati yangilandi';
  }

  async adminCancel(id: string): Promise<StoreOrder | null> {
    const order = await this.repo.findById(id);
    if (!order) return null;
    if (['DELIVERED', 'COMPLETED', 'CANCELLED'].includes(order.status)) return order;
    this.dispatch.clear(id);
    const cancelled = await this.repo.updateStatus(id, 'CANCELLED', { by: 'admin', driverId: order.driverId });
    await this.releaseOrderStock(order);
    return cancelled;
  }

  async adminListOrders(filter: {
    status?: string;
    deliveryMethod?: string;
    from?: string;
    to?: string;
    q?: string;
  }): Promise<AdminStoreOrderView[]> {
    const fromTs = filter.from
      ? new Date(filter.from.length === 10 ? `${filter.from}T00:00:00.000` : filter.from).getTime()
      : undefined;
    const toTs = filter.to
      ? new Date(filter.to.length === 10 ? `${filter.to}T23:59:59.999` : filter.to).getTime()
      : undefined;
    // Qidiruv ikki rejimda: sof raqam ("12" yoki "#12") — buyurtma raqami
    // bo'yicha ANIQ moslik; aks holda matn — mahsulot nomi/o'lcham/manzil.
    // (Aralashtirilsa "5" so'rovi "Coca-Cola 1.5L"ga ham tushib ketardi.)
    const rawQuery = filter.q?.trim() ?? '';
    const numericQuery = /^#?\d+$/.test(rawQuery)
      ? rawQuery.replace(/^#/, '')
      : undefined;
    const textQuery = numericQuery ? undefined : rawQuery.toLowerCase() || undefined;
    const orders = await this.repo.findAll();
    const filtered = orders.filter((o) => {
      if (filter.status && o.status !== filter.status) return false;
      if (filter.deliveryMethod && o.deliveryMethod !== filter.deliveryMethod) return false;
      const ts = new Date(o.createdAt).getTime();
      if (fromTs !== undefined && ts < fromTs) return false;
      if (toTs !== undefined && ts > toTs) return false;
      if (numericQuery && `${o.publicNo}` !== numericQuery) return false;
      if (textQuery) {
        const hay = [
          ...o.items.map((it) => `${it.nameSnapshot} ${it.size ?? ''}`),
          o.address?.text ?? '',
        ]
          .join(' ')
          .toLowerCase();
        if (!hay.includes(textQuery)) return false;
      }
      return true;
    });
    const customers = await this.driverInfo.getUsersInfo(filtered.map((o) => o.customerId));
    return filtered.map((o) => this.toAdminView(o, customers.get(o.customerId) ?? null));
  }

  async adminGetById(id: string): Promise<AdminStoreOrderView | null> {
    const order = await this.repo.findById(id);
    if (!order) return null;
    const customer = await this.driverInfo.getUserInfo(order.customerId);
    return this.toAdminView(order, customer);
  }

  /** Buyurtma + ruxsat etilgan o'tishlar + mijoz ism/telefoni (best-effort). */
  private toAdminView(order: StoreOrder, customer: UserBasicInfo | null): AdminStoreOrderView {
    return {
      ...order,
      allowedTransitions: this.allowedAdminTransitions(order),
      customer: customer ? { fullName: customer.fullName, phone: customer.phone } : null,
    };
  }

  async adminReport(period: ReportPeriod) {
    const orders = await this.repo.findAllForStats();
    return buildVerticalReport(orders, period, {
      createdAtOf: (o) => o.createdAt,
      isDone: (o) => o.status === 'DELIVERED' || o.status === 'COMPLETED',
      isCancelled: (o) => o.status === 'CANCELLED',
      revenueOf: (o) => o.total,
      profitOf: (_o) => 0, // Market yetkazishda komissiya yo'q; itemsTotal — mahsulot narxi (foyda emas)
    });
  }

  async adminReportRange(from: Date, to: Date) {
    const orders = await this.repo.findAllForStats();
    return buildVerticalReportRange(orders, from, to, {
      createdAtOf: (o) => o.createdAt,
      isDone: (o) => o.status === 'DELIVERED' || o.status === 'COMPLETED',
      isCancelled: (o) => o.status === 'CANCELLED',
      revenueOf: (o) => o.total,
      profitOf: (_o) => 0,
    });
  }

  async adminStats() {
    const orders = await this.repo.findAllForStats();
    return buildVerticalStats(orders, {
      isDone: (o) => o.status === 'DELIVERED' || o.status === 'COMPLETED',
      revenueOf: (o) => o.total,
      profitOf: (_o) => 0,
    });
  }

  private notifyCustomer(order: StoreOrder, body: string): Promise<void> {
    return this.notifications.notify(order.customerId, 'Market', body, {
      type: 'store',
      id: order.id,
      status: order.status,
    });
  }
}
