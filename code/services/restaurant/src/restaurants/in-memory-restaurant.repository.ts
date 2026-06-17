import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { Category, MenuItem, Restaurant } from './entities';
import {
  CreateCategoryData,
  CreateMenuItemData,
  RestaurantRepository,
} from './restaurant.repository';
import { buildSeed } from './seed';

/**
 * Xotirada saqlovchi katalog repository — FAQAT dev/test uchun.
 * TODO(Docker): PrismaRestaurantRepository (PostgreSQL restaurant_db).
 */
@Injectable()
export class InMemoryRestaurantRepository extends RestaurantRepository {
  private readonly restaurants = new Map<string, Restaurant>();
  private readonly categories = new Map<string, Category>();
  private readonly menuItems = new Map<string, MenuItem>();

  /** Namunaviy ma'lumot bilan to'ldirish (dev). */
  seedSampleData(): void {
    const seed = buildSeed();
    seed.restaurants.forEach((r) => this.restaurants.set(r.id, r));
    seed.categories.forEach((c) => this.categories.set(c.id, c));
    seed.menuItems.forEach((m) => this.menuItems.set(m.id, m));
  }

  async listRestaurants(): Promise<Restaurant[]> {
    return [...this.restaurants.values()];
  }

  async getRestaurant(id: string): Promise<Restaurant | null> {
    return this.restaurants.get(id) ?? null;
  }

  async listCategories(restaurantId: string): Promise<Category[]> {
    return [...this.categories.values()]
      .filter((c) => c.restaurantId === restaurantId)
      .sort((a, b) => a.sortOrder - b.sortOrder);
  }

  async createCategory(data: CreateCategoryData): Promise<Category> {
    this.assertRestaurant(data.restaurantId);
    const category: Category = {
      id: randomUUID(),
      restaurantId: data.restaurantId,
      name: data.name,
      sortOrder: data.sortOrder ?? 0,
    };
    this.categories.set(category.id, category);
    return category;
  }

  async updateCategory(
    restaurantId: string,
    id: string,
    patch: Partial<Omit<Category, 'id' | 'restaurantId'>>,
  ): Promise<Category> {
    const existing = this.getOwned(this.categories, restaurantId, id, 'Kategoriya');
    const updated: Category = {
      ...existing,
      ...patch,
      id: existing.id,
      restaurantId: existing.restaurantId,
    };
    this.categories.set(id, updated);
    return updated;
  }

  async deleteCategory(restaurantId: string, id: string): Promise<void> {
    this.getOwned(this.categories, restaurantId, id, 'Kategoriya');
    this.categories.delete(id);
    // Kategoriyadagi taomlar ham o'chiriladi.
    for (const [key, item] of this.menuItems) {
      if (item.categoryId === id) this.menuItems.delete(key);
    }
  }

  async listMenuItems(restaurantId: string): Promise<MenuItem[]> {
    return [...this.menuItems.values()].filter(
      (m) => m.restaurantId === restaurantId,
    );
  }

  async createMenuItem(data: CreateMenuItemData): Promise<MenuItem> {
    this.assertRestaurant(data.restaurantId);
    this.getOwned(this.categories, data.restaurantId, data.categoryId, 'Kategoriya');
    const item: MenuItem = {
      id: randomUUID(),
      restaurantId: data.restaurantId,
      categoryId: data.categoryId,
      name: data.name,
      description: data.description,
      price: data.price,
      imageUrl: data.imageUrl,
      isAvailable: data.isAvailable ?? true,
      createdAt: new Date().toISOString(),
    };
    this.menuItems.set(item.id, item);
    return item;
  }

  async updateMenuItem(
    restaurantId: string,
    id: string,
    patch: Partial<Omit<MenuItem, 'id' | 'restaurantId' | 'createdAt'>>,
  ): Promise<MenuItem> {
    const existing = this.getOwned(this.menuItems, restaurantId, id, 'Taom');
    const updated: MenuItem = {
      ...existing,
      ...patch,
      id: existing.id,
      restaurantId: existing.restaurantId,
      createdAt: existing.createdAt,
    };
    this.menuItems.set(id, updated);
    return updated;
  }

  async deleteMenuItem(restaurantId: string, id: string): Promise<void> {
    this.getOwned(this.menuItems, restaurantId, id, 'Taom');
    this.menuItems.delete(id);
  }

  private assertRestaurant(id: string): void {
    if (!this.restaurants.has(id)) {
      throw new NotFoundException('Oshxona topilmadi');
    }
  }

  private getOwned<T extends { id: string; restaurantId: string }>(
    map: Map<string, T>,
    restaurantId: string,
    id: string,
    label: string,
  ): T {
    const entity = map.get(id);
    if (!entity || entity.restaurantId !== restaurantId) {
      throw new NotFoundException(`${label} topilmadi`);
    }
    return entity;
  }
}
