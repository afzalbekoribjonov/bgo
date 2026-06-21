export interface Stats {
  totalOrders: number;
  activeOrders: number;
  todayOrders: number;
  revenue: number;
  profit: number;
  byStatus: Record<string, number>;
}

export interface Tariff {
  id: string;
  deliveryFee: number;
  foodCommissionPercent: number;
  courierSharePercent: number;
}

export interface PromoCode {
  id: string;
  code: string;
  type: 'PERCENT' | 'FIXED';
  value: number;
  minOrder: number;
  maxDiscount: number | null;
  active: boolean;
  usedCount: number;
}

export interface AdminOrder {
  id: string;
  publicNo: number;
  type: string;
  status: string;
  total: number;
  address: { text: string };
  createdAt: string;
}

export interface Restaurant {
  id: string;
  name: string;
  address: string;
  isOpen: boolean;
  rating: number;
}

export interface PartnerApplication {
  id: string;
  phone: string;
  fullName: string;
  type: 'RESTAURANT' | 'DRIVER';
  note: string | null;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  createdAt: string;
}
