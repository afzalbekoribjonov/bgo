import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PromoService } from '../promo/promo.service';
import { RestaurantClient } from '../restaurant-client/restaurant.client';
import { TariffService } from '../tariff/tariff.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { Order, OrderItem } from './entities';
import { OrderRepository } from './order.repository';

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

  async adminStats() {
    const orders = await this.repo.findAll();
    const terminal = ['DELIVERED', 'COMPLETED'];
    const closed = [...terminal, 'CANCELLED', 'FAILED'];

    const byStatus: Record<string, number> = {};
    let revenue = 0;
    let profit = 0;
    let today = 0;
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    for (const o of orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
      if (terminal.includes(o.status)) {
        revenue += o.total;
        // bizning foyda = komissiya + (yetkazish - kuryer ulushi) - chegirma
        profit += o.commission + (o.deliveryFee - o.courierEarning) - o.discount;
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

  async adminListOrders(filter: { status?: string; type?: string }) {
    const orders = await this.repo.findAll();
    return orders.filter(
      (o) =>
        (!filter.status || o.status === filter.status) &&
        (!filter.type || o.type === filter.type),
    );
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
  async driverEarnings(driverId: string) {
    const orders = await this.repo.findByDriver(driverId);
    const delivered = orders.filter((o) => o.status === 'DELIVERED');
    const totalEarning = delivered.reduce((sum, o) => sum + o.courierEarning, 0);
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayDelivered = delivered.filter(
      (o) => new Date(o.createdAt) >= todayStart,
    );
    const todayEarning = todayDelivered.reduce(
      (sum, o) => sum + o.courierEarning,
      0,
    );
    return {
      deliveredCount: delivered.length,
      totalEarning,
      todayDeliveredCount: todayDelivered.length,
      todayEarning,
      activeCount: orders.filter((o) =>
        ['ASSIGNED', 'PICKED_UP'].includes(o.status),
      ).length,
    };
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
