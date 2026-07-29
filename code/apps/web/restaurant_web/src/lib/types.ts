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
  logoUrl?: string | null;
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
  imageUrl?: string | null;
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
  serviceFee?: number;
  deliveryFee: number;
  total: number;
  status: OrderStatus;
  driverId?: string | null;
  kitchenAcceptedAt?: string | null;
  driverAcceptedAt?: string | null;
  address: { text: string };
  createdAt: string;
}

/** Oshxona↔haydovchi suhbat xabari. */
export interface OrderMessage {
  id: string;
  senderRole: 'kitchen' | 'driver';
  text: string;
  createdAt: string;
}

export interface WeeklyPoint {
  date: string;
  orders: number;
  revenue: number;
}

export interface KitchenStats {
  totalOrders: number;
  totalDelivered: number;
  totalRevenue: number;
  todayOrders: number;
  todayDelivered: number;
  todayRevenue: number;
  cancelledToday: number;
  avgOrderValue: number;
  weekly: WeeklyPoint[];
}
