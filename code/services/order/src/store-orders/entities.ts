import { GeoPoint } from '../common/geo';

export type StoreOrderStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'ARRIVED'
  | 'PICKED_UP'
  | 'IN_TRANSIT'
  | 'DELIVERED'
  | 'READY_FOR_PICKUP'
  | 'COMPLETED'
  | 'CANCELLED';

export type StoreDeliveryMethod = 'DELIVERY' | 'PICKUP';

export type StatusActor = 'customer' | 'driver' | 'admin' | 'system';

export interface StoreOrderStatusEntry {
  status: StoreOrderStatus;
  at: string;
  by?: StatusActor;
  driverId?: string;
  reason?: string;
}

/** Buyurtma paytidagi narx/nom "snapshot" — keyin mahsulot o'zgarsa ham hisobot to'g'ri. */
export interface StoreOrderItem {
  productId: string;
  nameSnapshot: string;
  priceSnapshot: number;
  qty: number;
  lineTotal: number;
  /** Tanlangan o'lcham — mahsulot o'lchamsiz bo'lsa yo'q. */
  size?: string;
}

export interface StoreOrder {
  id: string;
  publicNo: number;
  customerId: string;
  driverId?: string;
  pickupLocationId: string;
  deliveryMethod: StoreDeliveryMethod;
  address?: GeoPoint; // faqat DELIVERY
  items: StoreOrderItem[];
  itemsTotal: number;
  deliveryFee: number; // faqat DELIVERY (0 — PICKUP)
  courierEarning: number; // = deliveryFee (komissiyasiz)
  total: number; // itemsTotal + deliveryFee
  status: StoreOrderStatus;
  paymentType: 'CASH';
  statusHistory: StoreOrderStatusEntry[];
  rating?: number;
  ratingComment?: string;
  createdAt: string;
  updatedAt: string;
}

/**
 * Admin ro'yxati uchun ko'rinish — buyurtma + shu bosqichda ruxsat etilgan
 * holat o'tishlari (UI tugmalarni shu ro'yxatdan chizadi, mantiq serverda)
 * + mijoz ism/telefoni (aloqa/chat uchun, best-effort — auth servisidan).
 */
export interface AdminStoreOrderView extends StoreOrder {
  allowedTransitions: StoreOrderStatus[];
  customer: { fullName: string | null; phone: string } | null;
}

/** Jonli ko'rinish — faol buyurtmada biriktirilgan haydovchi ma'lumoti (mijozga). */
export interface StoreOrderLive extends StoreOrder {
  pickupLocationName?: string | null;
  pickupLat?: number;
  pickupLng?: number;
  driverName?: string | null;
  driverCar?: string | null;
  driverPlate?: string | null;
  driverPhone?: string | null;
  customerPhone?: string | null;
}

export interface NewStoreOrder {
  customerId: string;
  pickupLocationId: string;
  deliveryMethod: StoreDeliveryMethod;
  address?: GeoPoint;
  items: StoreOrderItem[];
  itemsTotal: number;
  deliveryFee: number;
  courierEarning: number;
  total: number;
}
