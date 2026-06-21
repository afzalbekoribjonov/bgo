export interface VerticalStat {
  count: number;
  revenue: number;
  profit: number;
}

export interface Stats {
  totalOrders: number;
  activeOrders: number;
  todayOrders: number;
  revenue: number;
  profit: number;
  byStatus: Record<string, number>;
  byVertical?: { food: VerticalStat; taxi: VerticalStat; parcel: VerticalStat };
}

export interface Tariff {
  id: string;
  deliveryFee: number;
  foodCommissionPercent: number;
  courierSharePercent: number;
  taxiBaseFare: number;
  taxiPerKm: number;
  taxiMinFare: number;
  taxiCommissionPercent: number;
  parcelBaseFare: number;
  parcelPerKm: number;
  parcelMinFare: number;
  parcelCommissionPercent: number;
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

export interface AdminRestaurant {
  id: string;
  name: string;
  address: string;
  phone: string;
  lat: number;
  lng: number;
  isOpen: boolean;
  rating: number;
  status: 'ACTIVE' | 'PENDING' | 'BLOCKED';
  commissionPercent: number;
  ownerUserId: string | null;
  createdAt: string;
}

export interface CreateRestaurantInput {
  name: string;
  address: string;
  phone: string;
  commissionPercent?: number;
}

export interface UpdateRestaurantInput {
  name?: string;
  address?: string;
  phone?: string;
  isOpen?: boolean;
  commissionPercent?: number;
  status?: 'ACTIVE' | 'PENDING' | 'BLOCKED';
}

export type ReportPeriod = 'today' | 'week' | 'month';

export interface ReportDayPoint {
  date: string; // YYYY-MM-DD
  orders: number;
  revenue: number;
  profit: number;
}

export interface Report {
  period: ReportPeriod;
  from: string;
  to: string;
  summary: {
    totalOrders: number;
    delivered: number;
    cancelled: number;
    revenue: number;
    profit: number;
    avgOrder: number;
  };
  daily: ReportDayPoint[];
  byVertical?: {
    food: { revenue: number; profit: number; delivered: number };
    taxi: { revenue: number; profit: number; delivered: number };
    parcel: { revenue: number; profit: number; delivered: number };
  };
}

export interface OrdersQuery {
  status?: string;
  type?: string;
  from?: string;
  to?: string;
  q?: string;
  sort?: 'createdAt' | 'total';
  order?: 'asc' | 'desc';
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
