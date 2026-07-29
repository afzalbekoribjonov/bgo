export type OrderType = 'FOOD' | 'TAXI' | 'DELIVERY';

export type OrderStatus =
  | 'PENDING' // yaratildi, oshxona tasdig'i kutilmoqda
  | 'ACCEPTED' // oshxona qabul qildi
  | 'PREPARING' // tayyorlanmoqda
  | 'READY' // tayyor (kuryer kutilmoqda)
  | 'ASSIGNED' // haydovchi biriktirildi
  | 'IN_PROGRESS'
  | 'PICKED_UP'
  | 'DELIVERED'
  | 'COMPLETED'
  | 'CANCELLED'
  | 'FAILED';

export type PaymentType = 'CASH' | 'PAYME' | 'CLICK' | 'UZUM';

export interface OrderAddress {
  text: string;
  lat?: number;
  lng?: number;
}

/** Buyurtma paytidagi narx/nom "snapshot" — keyin menyu o'zgarsa ham hisobot to'g'ri. */
export interface OrderItem {
  menuItemId: string;
  nameSnapshot: string;
  priceSnapshot: number; // oshxona narxi (haydovchi oshxonaga shu narxni to'laydi)
  markup: number; // per-dona xizmat haqi ustamasi (platforma daromadi)
  qty: number;
  lineTotal: number; // oshxona narxi × qty (haydovchi to'lovi)
}

/** Kim/nima sabab bilan holatni o'zgartirdi — audit va "kim bekor qildi" uchun. */
export type StatusActor = 'customer' | 'kitchen' | 'driver' | 'admin' | 'system';

export interface OrderStatusEntry {
  status: OrderStatus;
  at: string;
  by?: StatusActor;
  /** Shu o'tishga aloqador haydovchi (masalan, haydovchi voz kechganda — joriy driverId tozalangandan keyin ham saqlanib qoladi). */
  driverId?: string;
  reason?: string;
}

export interface Order {
  id: string;
  publicNo: number;
  customerId: string;
  driverId?: string;
  type: OrderType;
  restaurantId: string;
  items: OrderItem[];
  itemsTotal: number; // oshxona taom summasi (haydovchi oshxonaga to'laydi)
  serviceFee: number; // xizmat haqi (Σ ustama) — platforma daromadi, haydovchi balansidan
  deliveryFee: number; // yetkazish (haydovchi to'liq oladi — komissiyasiz)
  commission: number; // eskirgan (0)
  courierEarning: number; // haydovchi daromadi = deliveryFee
  promoCode?: string;
  discount: number;
  total: number; // mijoz to'lovi = itemsTotal + serviceFee + deliveryFee − discount
  paymentType: PaymentType;
  address: OrderAddress;
  /** Haydovchi GPS orqali haqiqatda bosib o'tgan masofa (oshxonadan mijozgacha, narxga ta'sir qilmaydi). */
  actualDistanceKm?: number;
  status: OrderStatus;
  kitchenAcceptedAt?: string | null;
  driverAcceptedAt?: string | null;
  rating?: number | null;
  ratingComment?: string | null;
  statusHistory: OrderStatusEntry[];
  createdAt: string;
  updatedAt: string;
}

/** Admin statistika/hisobot uchun qisqartirilgan qator (select — items/address/statusHistory'siz). */
export interface OrderStatsRow {
  status: OrderStatus;
  createdAt: string;
  total: number;
  serviceFee: number;
  discount: number;
  driverId?: string;
}

/** Haydovchi daromadi/statistikasi uchun qisqartirilgan qator. */
export interface OrderEarningsRow {
  status: OrderStatus;
  createdAt: string;
  total: number;
  courierEarning: number;
  updatedAt: string;
}

export type ChatRole = 'kitchen' | 'driver';

/** Ovqat buyurtmasi suhbat xabari (oshxona↔haydovchi). */
export interface OrderMessage {
  id: string;
  orderId: string;
  senderId: string;
  senderRole: ChatRole;
  text: string;
  createdAt: string;
}

export interface NewOrderMessage {
  orderId: string;
  senderId: string;
  senderRole: ChatRole;
  text: string;
}
