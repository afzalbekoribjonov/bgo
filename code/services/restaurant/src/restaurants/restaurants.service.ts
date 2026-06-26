import { Injectable, NotFoundException } from '@nestjs/common';
import { pickLocale, SupportedLocale } from '../common/i18n';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import { CreateMenuItemDto, UpdateMenuItemDto } from './dto/menu-item.dto';
import { CreateRestaurantDto, UpdateRestaurantDto } from './dto/restaurant.dto';
import { Restaurant } from './entities';
import { RestaurantRepository } from './restaurant.repository';

@Injectable()
export class RestaurantsService {
  constructor(private readonly repo: RestaurantRepository) {}

  // ---------- Public katalog (mijoz) ----------

  async listPublicRestaurants() {
    const restaurants = await this.repo.listRestaurants();
    return restaurants
      .filter((r) => r.status === 'ACTIVE')
      .map((r) => this.toPublicRestaurant(r));
  }

  async getPublicRestaurant(id: string) {
    const restaurant = await this.requireRestaurant(id);
    return this.toPublicRestaurant(restaurant);
  }

  /**
   * Bosh ekran uchun taomlar lentasi — barcha faol oshxonalardagi mavjud
   * taomlar, oshxona reytingi bo'yicha tartiblangan (yuqori reyting birinchi).
   * Mijoz lat/lng bo'yicha yaqinlikni o'zi qayta tartiblay oladi (restoran
   * koordinatalari ham qaytariladi).
   */
  async listPopularDishes(locale: SupportedLocale, limit = 50) {
    const items = await this.repo.listAvailableItemsWithRestaurant();
    return items
      .filter((it) => it.restaurant.isOpen)
      .map((it) => ({
        id: it.id,
        name: pickLocale(it.name, locale),
        description: it.description ? pickLocale(it.description, locale) : null,
        price: it.price,
        imageUrl: it.imageUrl ?? null,
        restaurantId: it.restaurantId,
        restaurantName: it.restaurant.name,
        restaurantRating: it.restaurant.rating,
        restaurantLat: it.restaurant.lat,
        restaurantLng: it.restaurant.lng,
      }))
      .sort((a, b) => b.restaurantRating - a.restaurantRating)
      .slice(0, limit);
  }

  // ---------- Egalik (ownership) ----------

  /** Foydalanuvchiga tegishli oshxonalar (restaurant roli). */
  async listForOwner(ownerUserId: string) {
    const restaurants = await this.repo.findByOwner(ownerUserId);
    return restaurants.map((r) => this.toPublicRestaurant(r));
  }

  /** Egasini biriktirish (admin). */
  async assignOwner(id: string, ownerUserId: string) {
    const restaurant = await this.repo.setOwner(id, ownerUserId);
    return this.toPublicRestaurant(restaurant);
  }

  // ---------- Admin onboarding ----------

  /** Barcha oshxonalar (admin ko'rinishi — ega/status/komissiya bilan). */
  async adminListRestaurants() {
    const restaurants = await this.repo.listRestaurants();
    return restaurants
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .map((r) => this.toAdminRestaurant(r));
  }

  /** Yangi oshxona yaratish (admin). */
  async createRestaurant(dto: CreateRestaurantDto) {
    const restaurant = await this.repo.createRestaurant(dto);
    return this.toAdminRestaurant(restaurant);
  }

  /** Oshxona ma'lumotlarini yangilash (admin). */
  async updateRestaurant(id: string, dto: UpdateRestaurantDto) {
    await this.requireRestaurant(id);
    const restaurant = await this.repo.updateRestaurant(id, dto);
    return this.toAdminRestaurant(restaurant);
  }

  /** Foydalanuvchi shu oshxona egasimi? (OwnerGuard uchun) */
  async isOwner(restaurantId: string, userId: string): Promise<boolean> {
    const restaurant = await this.repo.getRestaurant(restaurantId);
    return !!restaurant && restaurant.ownerUserId === userId;
  }

  /** Oshxona menyusi — kategoriyalar bo'yicha guruhlangan, tilga moslangan. */
  async getMenu(id: string, locale: SupportedLocale) {
    const restaurant = await this.requireRestaurant(id);
    const [categories, items] = await Promise.all([
      this.repo.listCategories(id),
      this.repo.listMenuItems(id),
    ]);

    const categoriesWithItems = categories.map((category) => ({
      id: category.id,
      name: pickLocale(category.name, locale),
      items: items
        .filter((item) => item.categoryId === category.id)
        .map((item) => ({
          id: item.id,
          name: pickLocale(item.name, locale),
          description: item.description ? pickLocale(item.description, locale) : null,
          price: item.price,
          imageUrl: item.imageUrl ?? null,
          isAvailable: item.isAvailable,
        })),
    }));

    return {
      restaurant: this.toPublicRestaurant(restaurant),
      categories: categoriesWithItems,
    };
  }

  // ---------- Boshqaruv (oshxona egasi) ----------
  // TODO(restaurant_web auth): restaurantId egalik tekshiruvi JWT (restaurant roli) orqali.

  listCategories(restaurantId: string) {
    return this.repo.listCategories(restaurantId);
  }

  createCategory(restaurantId: string, dto: CreateCategoryDto) {
    return this.repo.createCategory({
      restaurantId,
      name: dto.name,
      sortOrder: dto.sortOrder,
    });
  }

  updateCategory(restaurantId: string, id: string, dto: UpdateCategoryDto) {
    return this.repo.updateCategory(restaurantId, id, dto);
  }

  deleteCategory(restaurantId: string, id: string) {
    return this.repo.deleteCategory(restaurantId, id);
  }

  listMenuItems(restaurantId: string) {
    return this.repo.listMenuItems(restaurantId);
  }

  createMenuItem(restaurantId: string, dto: CreateMenuItemDto) {
    return this.repo.createMenuItem({ restaurantId, ...dto });
  }

  updateMenuItem(restaurantId: string, id: string, dto: UpdateMenuItemDto) {
    return this.repo.updateMenuItem(restaurantId, id, dto);
  }

  setAvailability(restaurantId: string, id: string, isAvailable: boolean) {
    return this.repo.updateMenuItem(restaurantId, id, { isAvailable });
  }

  deleteMenuItem(restaurantId: string, id: string) {
    return this.repo.deleteMenuItem(restaurantId, id);
  }

  // ---------- yordamchilar ----------

  private async requireRestaurant(id: string): Promise<Restaurant> {
    const restaurant = await this.repo.getRestaurant(id);
    if (!restaurant) throw new NotFoundException('Oshxona topilmadi');
    return restaurant;
  }

  private toPublicRestaurant(r: Restaurant) {
    return {
      id: r.id,
      name: r.name,
      address: r.address,
      lat: r.lat,
      lng: r.lng,
      isOpen: r.isOpen,
      rating: r.rating,
      logoUrl: r.logoUrl ?? null,
    };
  }

  /** Admin ko'rinishi — to'liq (ega/status/telefon/komissiya). */
  private toAdminRestaurant(r: Restaurant) {
    return {
      id: r.id,
      name: r.name,
      address: r.address,
      phone: r.phone,
      lat: r.lat,
      lng: r.lng,
      isOpen: r.isOpen,
      rating: r.rating,
      status: r.status,
      commissionPercent: r.commissionPercent,
      ownerUserId: r.ownerUserId ?? null,
      createdAt: r.createdAt,
    };
  }
}
