import { ConflictException, Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AuthClient } from '../auth-client/auth.client';
import { OrderClient } from '../order-client/order.client';
import { pickLocale, SupportedLocale } from '@beshariq/i18n';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import { CreateMenuItemDto, UpdateMenuItemDto } from './dto/menu-item.dto';
import { CreateRestaurantDto, UpdateRestaurantDto } from './dto/restaurant.dto';
import { Restaurant } from './entities';
import { RestaurantRepository } from './restaurant.repository';

@Injectable()
export class RestaurantsService {
  constructor(
    private readonly repo: RestaurantRepository,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly authClient: AuthClient,
    private readonly orderClient: OrderClient,
  ) {}

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

  /**
   * "Mening oshxonam" — mijoz ilovasida allaqachon kirgan foydalanuvchi o'z
   * oshxonasi panelini WebView orqali avtomatik ochishi uchun. Egalik
   * `ownerUserId` bo'yicha SERVER tomonda tekshiriladi (rol talab qilinmaydi);
   * topilsa oshxona paneliga mos JWT (role 'restaurant' + restaurantId) beriladi.
   * Topilmasa `{ restaurantId: null }`.
   */
  async panelTokenForOwner(ownerUserId: string): Promise<{
    restaurantId: string | null;
    name?: string;
    accessToken?: string;
  }> {
    const restaurants = await this.repo.findByOwner(ownerUserId);
    const restaurant = restaurants[0];
    if (!restaurant) return { restaurantId: null };
    const accessToken = await this.jwt.signAsync(
      {
        sub: `kitchen:${restaurant.id}`,
        phone: '',
        roles: ['restaurant'],
        restaurantId: restaurant.id,
      },
      {
        secret: this.config.get<string>('JWT_ACCESS_SECRET'),
        expiresIn: this.config.get<string>('JWT_ACCESS_TTL') ?? '30m',
      },
    );
    return { restaurantId: restaurant.id, name: restaurant.name, accessToken };
  }

  /** Egasini biriktirish (admin) — xom UUID bilan (ichki/qo'lda ishlatish uchun). */
  async assignOwner(id: string, ownerUserId: string) {
    const restaurant = await this.repo.setOwner(id, ownerUserId);
    return this.toPublicRestaurant(restaurant);
  }

  /**
   * Telefon raqami bo'yicha foydalanuvchini qidiradi — egani biriktirishdan
   * oldin admin panelda ko'rsatish/tasdiqlash uchun. Topilmasa null.
   */
  async findOwnerCandidate(phone: string) {
    return this.authClient.findUserByPhone(phone);
  }

  /**
   * Egani telefon raqami bo'yicha biriktiradi — userId avtomatik auth
   * servisidan topiladi (admin UUID kiritmaydi, xato ehtimoli yo'q).
   */
  async assignOwnerByPhone(id: string, phone: string) {
    await this.requireRestaurant(id);
    const user = await this.authClient.findUserByPhone(phone);
    if (!user) {
      throw new NotFoundException(
        "Bu telefon raqami bilan ro'yxatdan o'tgan foydalanuvchi topilmadi. Foydalanuvchi avval Beshariq Go ilovasiga shu raqam bilan kirishi kerak.",
      );
    }
    const restaurant = await this.repo.setOwner(id, user.id);
    return this.toAdminRestaurant(restaurant);
  }

  // ---------- Admin onboarding ----------

  /** Barcha oshxonalar (admin ko'rinishi — ega/status/komissiya bilan). */
  async adminListRestaurants() {
    const restaurants = await this.repo.listRestaurants();
    const sorted = restaurants.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    // Egalar ma'lumotini oldindan bitta so'rovda olib keshni isitadi —
    // `toAdminRestaurant`ning ichidagi yakka `getUserById` kesh-hit bo'ladi.
    const ownerIds = sorted
      .map((r) => r.ownerUserId)
      .filter((v): v is string => !!v);
    await this.authClient.getUsersById(ownerIds);
    return Promise.all(sorted.map((r) => this.toAdminRestaurant(r)));
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

  /**
   * Oshxonani butunlay o'chiradi (admin) — qaytarib bo'lmaydi. Menyu/kategoriya
   * shu bazada kaskad o'chadi; buyurtma tarixi (order servisida, alohida baza)
   * teginmaydi — mavjud kod BLOCKED/faolsiz oshxona uchun ham xuddi shunday
   * "restaurant: null" bilan degradatsiya qiladi (yangi xatti-harakat emas).
   *
   * Xavfsizlik tekshiruvi: hali yakunlanmagan buyurtmalar bo'lsa bloklanadi
   * (order servisi bilan aloqa bo'lmasa ham — FAIL-CLOSED, chunki bu
   * qaytarib bo'lmaydigan amal).
   */
  async deleteRestaurant(id: string): Promise<void> {
    await this.requireRestaurant(id);
    const activeCount = await this.orderClient.getActiveOrderCount(id);
    if (activeCount === null) {
      throw new ServiceUnavailableException(
        "Buyurtmalar xizmati bilan aloqa yo'q — xavfsizlik uchun o'chirish vaqtincha bloklandi. Birozdan so'ng qayta urinib ko'ring.",
      );
    }
    if (activeCount > 0) {
      throw new ConflictException(
        `Bu oshxonada ${activeCount} ta hali yakunlanmagan buyurtma bor — avval ularni yakunlang yoki bekor qiling.`,
      );
    }
    await this.authClient.deleteKitchenCredential(id);
    await this.repo.deleteRestaurant(id);
  }

  /** Oshxonani ochiq/yopiq (faol/faolsiz) qiladi — ega paneli yoki tizim. */
  async setOpen(id: string, isOpen: boolean) {
    await this.requireRestaurant(id);
    const restaurant = await this.repo.updateRestaurant(id, { isOpen });
    return this.toAdminRestaurant(restaurant);
  }

  /** Oshxona logotipini (profil rasmini) yangilaydi — ega paneli. */
  async updateLogo(id: string, logoUrl: string) {
    await this.requireRestaurant(id);
    const restaurant = await this.repo.updateRestaurant(id, { logoUrl });
    return this.toAdminRestaurant(restaurant);
  }

  /** Foydalanuvchi shu oshxona egasimi? (OwnerGuard uchun) */
  async isOwner(restaurantId: string, userId: string): Promise<boolean> {
    const restaurant = await this.repo.getRestaurant(restaurantId);
    return !!restaurant && restaurant.ownerUserId === userId;
  }

  /**
   * Oshxona egasining userId'si — faqat ichki (internal) chaqiruvchilar
   * uchun (masalan order servisi yangi buyurtmada push yuborish uchun).
   */
  async getOwnerUserId(restaurantId: string): Promise<string | null> {
    const restaurant = await this.repo.getRestaurant(restaurantId);
    return restaurant?.ownerUserId ?? null;
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
  private async toAdminRestaurant(r: Restaurant) {
    const owner = r.ownerUserId
      ? await this.authClient.getUserById(r.ownerUserId)
      : null;
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
      logoUrl: r.logoUrl ?? null,
      ownerUserId: r.ownerUserId ?? null,
      ownerPhone: owner?.phone ?? null,
      ownerName: owner?.fullName ?? null,
      createdAt: r.createdAt,
    };
  }
}
