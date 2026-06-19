export interface Stats {
  totalOrders: number;
  activeOrders: number;
  todayOrders: number;
  revenue: number;
  byStatus: Record<string, number>;
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
