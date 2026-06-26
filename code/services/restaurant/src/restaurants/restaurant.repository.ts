import { Category, MenuItem, Restaurant, RestaurantStatus } from './entities';

export interface CreateRestaurantData {
  name: string;
  address: string;
  phone: string;
  lat?: number;
  lng?: number;
  commissionPercent?: number;
  isOpen?: boolean;
  ownerUserId?: string;
}

export type UpdateRestaurantData = Partial<{
  name: string;
  address: string;
  phone: string;
  lat: number;
  lng: number;
  commissionPercent: number;
  isOpen: boolean;
  status: RestaurantStatus;
}>;

export interface CreateCategoryData {
  restaurantId: string;
  name: Category['name'];
  sortOrder?: number;
}

export interface CreateMenuItemData {
  restaurantId: string;
  categoryId: string;
  name: MenuItem['name'];
  description?: MenuItem['description'];
  price: number;
  imageUrl?: string;
  isAvailable?: boolean;
}

/** Taom + tegishli oshxona (bosh ekran "taomlar" lentasi uchun). */
export interface MenuItemWithRestaurant extends MenuItem {
  restaurant: Restaurant;
}

/**
 * Katalog repository interfeysi — saqlash texnologiyasidan mustaqil.
 * Hozir: in-memory (dev). Keyin: Prisma/PostgreSQL (plan/03-databases.md).
 */
export abstract class RestaurantRepository {
  abstract listRestaurants(): Promise<Restaurant[]>;
  abstract getRestaurant(id: string): Promise<Restaurant | null>;
  /** Egalik: shu foydalanuvchiga tegishli oshxonalar. */
  abstract findByOwner(ownerUserId: string): Promise<Restaurant[]>;
  abstract setOwner(id: string, ownerUserId: string): Promise<Restaurant>;
  /** Yangi oshxona yaratish (admin onboarding). */
  abstract createRestaurant(data: CreateRestaurantData): Promise<Restaurant>;
  /** Asosiy ma'lumotlarni yangilash (admin/ega). */
  abstract updateRestaurant(
    id: string,
    patch: UpdateRestaurantData,
  ): Promise<Restaurant>;

  abstract listCategories(restaurantId: string): Promise<Category[]>;
  abstract createCategory(data: CreateCategoryData): Promise<Category>;
  abstract updateCategory(
    restaurantId: string,
    id: string,
    patch: Partial<Omit<Category, 'id' | 'restaurantId'>>,
  ): Promise<Category>;
  abstract deleteCategory(restaurantId: string, id: string): Promise<void>;

  abstract listMenuItems(restaurantId: string): Promise<MenuItem[]>;
  /** Barcha faol oshxonalardagi mavjud taomlar (oshxona bilan birga). */
  abstract listAvailableItemsWithRestaurant(): Promise<MenuItemWithRestaurant[]>;
  abstract createMenuItem(data: CreateMenuItemData): Promise<MenuItem>;
  abstract updateMenuItem(
    restaurantId: string,
    id: string,
    patch: Partial<Omit<MenuItem, 'id' | 'restaurantId' | 'createdAt'>>,
  ): Promise<MenuItem>;
  abstract deleteMenuItem(restaurantId: string, id: string): Promise<void>;
}
