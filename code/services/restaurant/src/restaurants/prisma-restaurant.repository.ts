import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { I18nString } from '../common/i18n';
import { PrismaService } from '../prisma/prisma.service';
import { Category, MenuItem, Restaurant, RestaurantStatus } from './entities';
import {
  CreateCategoryData,
  CreateMenuItemData,
  CreateRestaurantData,
  RestaurantRepository,
  UpdateRestaurantData,
} from './restaurant.repository';
import { buildSeed } from './seed';

type Row = Record<string, unknown>;

/** Beshariq tumani markazi — yangi oshxona uchun standart koordinata. */
const BESHARIQ_CENTER = { lat: 40.4236, lng: 70.6094 };

/** PostgreSQL (restaurant_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaRestaurantRepository extends RestaurantRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  /** Bo'sh bo'lsa namunaviy katalog bilan to'ldiradi (idempotent). */
  async seedSampleData(): Promise<void> {
    const count = await this.prisma.restaurant.count();
    if (count > 0) return;
    const seed = buildSeed();
    for (const r of seed.restaurants) {
      await this.prisma.restaurant.create({
        data: {
          id: r.id,
          ownerUserId: r.ownerUserId,
          name: r.name,
          lat: r.lat,
          lng: r.lng,
          address: r.address,
          phone: r.phone,
          status: r.status,
          commissionPercent: r.commissionPercent,
          isOpen: r.isOpen,
          rating: r.rating,
          logoUrl: r.logoUrl,
          createdAt: new Date(r.createdAt),
        },
      });
    }
    for (const c of seed.categories) {
      await this.prisma.category.create({
        data: {
          id: c.id,
          restaurantId: c.restaurantId,
          name: c.name as unknown as Prisma.InputJsonValue,
          sortOrder: c.sortOrder,
        },
      });
    }
    for (const m of seed.menuItems) {
      await this.prisma.menuItem.create({
        data: {
          id: m.id,
          restaurantId: m.restaurantId,
          categoryId: m.categoryId,
          name: m.name as unknown as Prisma.InputJsonValue,
          description: (m.description ?? undefined) as unknown as Prisma.InputJsonValue,
          price: m.price,
          imageUrl: m.imageUrl,
          isAvailable: m.isAvailable,
          createdAt: new Date(m.createdAt),
        },
      });
    }
  }

  async listRestaurants(): Promise<Restaurant[]> {
    const rows = await this.prisma.restaurant.findMany();
    return rows.map((r) => this.toRestaurant(r as Row));
  }

  async getRestaurant(id: string): Promise<Restaurant | null> {
    const r = await this.prisma.restaurant.findUnique({ where: { id } });
    return r ? this.toRestaurant(r as Row) : null;
  }

  async findByOwner(ownerUserId: string): Promise<Restaurant[]> {
    const rows = await this.prisma.restaurant.findMany({
      where: { ownerUserId },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((r) => this.toRestaurant(r as Row));
  }

  async setOwner(id: string, ownerUserId: string): Promise<Restaurant> {
    await this.assertRestaurant(id);
    const r = await this.prisma.restaurant.update({
      where: { id },
      data: { ownerUserId },
    });
    return this.toRestaurant(r as Row);
  }

  async createRestaurant(data: CreateRestaurantData): Promise<Restaurant> {
    const r = await this.prisma.restaurant.create({
      data: {
        name: data.name,
        address: data.address,
        phone: data.phone,
        // Beshariq markazi (standart) — xarita keyin ulanadi
        lat: data.lat ?? BESHARIQ_CENTER.lat,
        lng: data.lng ?? BESHARIQ_CENTER.lng,
        ownerUserId: data.ownerUserId,
        commissionPercent: data.commissionPercent ?? 0,
        isOpen: data.isOpen ?? true,
        status: 'ACTIVE',
      },
    });
    return this.toRestaurant(r as Row);
  }

  async updateRestaurant(
    id: string,
    patch: UpdateRestaurantData,
  ): Promise<Restaurant> {
    await this.assertRestaurant(id);
    const r = await this.prisma.restaurant.update({
      where: { id },
      data: patch,
    });
    return this.toRestaurant(r as Row);
  }

  async listCategories(restaurantId: string): Promise<Category[]> {
    const rows = await this.prisma.category.findMany({
      where: { restaurantId },
      orderBy: { sortOrder: 'asc' },
    });
    return rows.map((c) => this.toCategory(c as Row));
  }

  async createCategory(data: CreateCategoryData): Promise<Category> {
    await this.assertRestaurant(data.restaurantId);
    const c = await this.prisma.category.create({
      data: {
        restaurantId: data.restaurantId,
        name: data.name as unknown as Prisma.InputJsonValue,
        sortOrder: data.sortOrder ?? 0,
      },
    });
    return this.toCategory(c as Row);
  }

  async updateCategory(
    restaurantId: string,
    id: string,
    patch: Partial<Omit<Category, 'id' | 'restaurantId'>>,
  ): Promise<Category> {
    await this.assertOwned('category', restaurantId, id, 'Kategoriya');
    const c = await this.prisma.category.update({
      where: { id },
      data: {
        ...(patch.name !== undefined
          ? { name: patch.name as unknown as Prisma.InputJsonValue }
          : {}),
        ...(patch.sortOrder !== undefined ? { sortOrder: patch.sortOrder } : {}),
      },
    });
    return this.toCategory(c as Row);
  }

  async deleteCategory(restaurantId: string, id: string): Promise<void> {
    await this.assertOwned('category', restaurantId, id, 'Kategoriya');
    // menu_items onDelete: Cascade — taomlar ham o'chadi
    await this.prisma.category.delete({ where: { id } });
  }

  async listMenuItems(restaurantId: string): Promise<MenuItem[]> {
    const rows = await this.prisma.menuItem.findMany({ where: { restaurantId } });
    return rows.map((m) => this.toMenuItem(m as Row));
  }

  async createMenuItem(data: CreateMenuItemData): Promise<MenuItem> {
    await this.assertRestaurant(data.restaurantId);
    await this.assertOwned('category', data.restaurantId, data.categoryId, 'Kategoriya');
    const m = await this.prisma.menuItem.create({
      data: {
        restaurantId: data.restaurantId,
        categoryId: data.categoryId,
        name: data.name as unknown as Prisma.InputJsonValue,
        description: (data.description ?? undefined) as unknown as Prisma.InputJsonValue,
        price: data.price,
        imageUrl: data.imageUrl,
        isAvailable: data.isAvailable ?? true,
      },
    });
    return this.toMenuItem(m as Row);
  }

  async updateMenuItem(
    restaurantId: string,
    id: string,
    patch: Partial<Omit<MenuItem, 'id' | 'restaurantId' | 'createdAt'>>,
  ): Promise<MenuItem> {
    await this.assertOwned('menuItem', restaurantId, id, 'Taom');
    const m = await this.prisma.menuItem.update({
      where: { id },
      data: {
        ...(patch.categoryId !== undefined ? { categoryId: patch.categoryId } : {}),
        ...(patch.name !== undefined
          ? { name: patch.name as unknown as Prisma.InputJsonValue }
          : {}),
        ...(patch.description !== undefined
          ? { description: patch.description as unknown as Prisma.InputJsonValue }
          : {}),
        ...(patch.price !== undefined ? { price: patch.price } : {}),
        ...(patch.imageUrl !== undefined ? { imageUrl: patch.imageUrl } : {}),
        ...(patch.isAvailable !== undefined ? { isAvailable: patch.isAvailable } : {}),
      },
    });
    return this.toMenuItem(m as Row);
  }

  async deleteMenuItem(restaurantId: string, id: string): Promise<void> {
    await this.assertOwned('menuItem', restaurantId, id, 'Taom');
    await this.prisma.menuItem.delete({ where: { id } });
  }

  // ---------- yordamchilar ----------

  private async assertRestaurant(id: string): Promise<void> {
    const exists = await this.prisma.restaurant.findUnique({ where: { id } });
    if (!exists) throw new NotFoundException('Oshxona topilmadi');
  }

  private async assertOwned(
    model: 'category' | 'menuItem',
    restaurantId: string,
    id: string,
    label: string,
  ): Promise<void> {
    const found =
      model === 'category'
        ? await this.prisma.category.findFirst({ where: { id, restaurantId } })
        : await this.prisma.menuItem.findFirst({ where: { id, restaurantId } });
    if (!found) throw new NotFoundException(`${label} topilmadi`);
  }

  private toRestaurant(r: Row): Restaurant {
    return {
      id: r.id as string,
      ownerUserId: (r.ownerUserId as string) ?? undefined,
      name: r.name as string,
      lat: r.lat as number,
      lng: r.lng as number,
      address: r.address as string,
      phone: r.phone as string,
      status: r.status as RestaurantStatus,
      commissionPercent: r.commissionPercent as number,
      isOpen: r.isOpen as boolean,
      rating: r.rating as number,
      logoUrl: (r.logoUrl as string) ?? undefined,
      createdAt: (r.createdAt as Date).toISOString(),
    };
  }

  private toCategory(c: Row): Category {
    return {
      id: c.id as string,
      restaurantId: c.restaurantId as string,
      name: c.name as unknown as I18nString,
      sortOrder: c.sortOrder as number,
    };
  }

  private toMenuItem(m: Row): MenuItem {
    return {
      id: m.id as string,
      restaurantId: m.restaurantId as string,
      categoryId: m.categoryId as string,
      name: m.name as unknown as I18nString,
      description: (m.description as unknown as I18nString) ?? undefined,
      price: m.price as number,
      imageUrl: (m.imageUrl as string) ?? undefined,
      isAvailable: m.isAvailable as boolean,
      createdAt: (m.createdAt as Date).toISOString(),
    };
  }
}
