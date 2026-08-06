export interface MarketSettings {
  minOrderAmount: number;
  isAcceptingOrders: boolean;
}

/** Sahifalab yuklangan mahsulot ro'yxati javobi. */
export interface PagedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface Category {
  id: string;
  name: string;
  sortOrder: number;
}

export interface Product {
  id: string;
  categoryId: string;
  name: string;
  description: string | null;
  price: number;
  stockQty: number;
  inStock: boolean;
  imageUrls: string[];
  /** Mavjud o'lchamlar — bo'sh bo'lsa mahsulot o'lchamsiz. */
  sizes: string[];
  likesCount: number;
  ratingAvg: number | null;
  liked?: boolean;
}

export interface ProductComment {
  id: string;
  productId: string;
  userId: string;
  text: string;
  createdAt: string;
  user: { id: string; phone: string; fullName: string | null } | null;
}

export interface PickupLocation {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  isActive: boolean;
}

export interface SupportMessage {
  id: string;
  customerId: string;
  senderRole: 'CUSTOMER' | 'SUPPORT';
  text: string;
  seenAt: string | null;
  createdAt: string;
}

export interface StoreOrderItem {
  productId: string;
  nameSnapshot: string;
  priceSnapshot: number;
  qty: number;
  lineTotal: number;
  /** Tanlangan o'lcham — mahsulot o'lchamsiz bo'lsa yo'q. */
  size?: string;
}

export type StoreOrderStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'ARRIVED'
  | 'PICKED_UP'
  | 'IN_TRANSIT'
  | 'DELIVERED'
  | 'PREPARING'
  | 'READY_FOR_PICKUP'
  | 'COMPLETED'
  | 'CANCELLED';

export interface StoreOrder {
  id: string;
  publicNo: number;
  customerId: string;
  driverId: string | null;
  pickupLocationId: string;
  deliveryMethod: 'DELIVERY' | 'PICKUP';
  address: { text: string; lat: number; lng: number } | null;
  items: StoreOrderItem[];
  itemsTotal: number;
  deliveryFee: number;
  courierEarning: number;
  total: number;
  status: StoreOrderStatus;
  rating?: number;
  /** PICKUP: READY_FOR_PICKUP'ga o'tgan vaqt. */
  readyAt?: string;
  createdAt: string;
  updatedAt: string;
  pickupLocationName?: string | null;
  driverName?: string | null;
  driverCar?: string | null;
  driverPlate?: string | null;
  driverPhone?: string | null;
}
