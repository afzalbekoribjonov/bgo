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
  priceSnapshot: number;
  qty: number;
  lineTotal: number;
}

export interface OrderStatusEntry {
  status: OrderStatus;
  at: string;
}

export interface Order {
  id: string;
  publicNo: number;
  customerId: string;
  type: OrderType;
  restaurantId: string;
  items: OrderItem[];
  itemsTotal: number;
  deliveryFee: number;
  total: number;
  paymentType: PaymentType;
  address: OrderAddress;
  status: OrderStatus;
  statusHistory: OrderStatusEntry[];
  createdAt: string;
}
