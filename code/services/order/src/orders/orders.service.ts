import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RestaurantClient } from '../restaurant-client/restaurant.client';
import { CreateOrderDto } from './dto/create-order.dto';
import { Order, OrderItem } from './entities';
import { OrderRepository } from './order.repository';

@Injectable()
export class OrdersService {
  private readonly deliveryFee: number;

  constructor(
    private readonly repo: OrderRepository,
    private readonly restaurant: RestaurantClient,
    config: ConfigService,
  ) {
    this.deliveryFee = Number(config.get('DELIVERY_FEE') ?? 5000);
  }

  /** Buyurtma yaratish — narx SERVER tomonda katalogdan hisoblanadi. */
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
    const total = itemsTotal + this.deliveryFee;

    return this.repo.create({
      customerId,
      type: dto.type,
      restaurantId: dto.restaurantId,
      items,
      itemsTotal,
      deliveryFee: this.deliveryFee,
      total,
      paymentType: dto.paymentType,
      address: dto.address,
    });
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
