export interface I18nString {
  uz: string;
  uz_Cyrl?: string;
  ru?: string;
}

export interface Restaurant {
  id: string;
  name: string;
  address: string;
  isOpen: boolean;
  rating: number;
}

export interface Category {
  id: string;
  restaurantId: string;
  name: I18nString;
  sortOrder: number;
}

export interface MenuItem {
  id: string;
  restaurantId: string;
  categoryId: string;
  name: I18nString;
  description?: I18nString;
  price: number;
  isAvailable: boolean;
}

export type OrderStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'PREPARING'
  | 'READY'
  | 'ASSIGNED'
  | 'IN_PROGRESS'
  | 'PICKED_UP'
  | 'DELIVERED'
  | 'COMPLETED'
  | 'CANCELLED'
  | 'FAILED';

export interface OrderItem {
  nameSnapshot: string;
  qty: number;
  lineTotal: number;
}

export interface Order {
  id: string;
  publicNo: number;
  items: OrderItem[];
  itemsTotal: number;
  deliveryFee: number;
  total: number;
  status: OrderStatus;
  address: { text: string };
  createdAt: string;
}
