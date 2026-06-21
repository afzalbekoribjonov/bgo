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
