import type {
  AdminOrder,
  AdminRestaurant,
  CreateAreaInput,
  CreateRestaurantInput,
  GeoPlace,
  OrdersQuery,
  PartnerApplication,
  PromoCode,
  Report,
  ReportPeriod,
  Restaurant,
  ServiceArea,
  Stats,
  Tariff,
  UpdateRestaurantInput,
} from './types';
import { clearToken, getToken } from './auth';

const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

async function api<T>(path: string, opts?: RequestInit): Promise<T> {
  const token = getToken();
  const res = await fetch(`${BASE}${path}`, {
    cache: 'no-store',
    ...opts,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(opts?.headers ?? {}),
    },
  });
  if (res.status === 401 || res.status === 403) {
    // Sessiya tugagan / ruxsat yo'q — qayta login
    clearToken();
    if (typeof window !== 'undefined') window.location.reload();
    throw new Error('Avtorizatsiya talab qilinadi');
  }
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    throw new Error(body?.error?.message ?? body?.message ?? `Xatolik (${res.status})`);
  }
  return body?.data as T;
}

export const getStats = () => api<Stats>('/admin/stats');
export const getReport = (period: ReportPeriod) =>
  api<Report>(`/admin/reports?period=${period}`);
export const getOrders = (query: OrdersQuery = {}) => {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value) params.set(key, String(value));
  }
  const qs = params.toString();
  return api<AdminOrder[]>(`/admin/orders${qs ? `?${qs}` : ''}`);
};
export const getRestaurants = () => api<Restaurant[]>('/restaurants');
export const getManageRestaurants = () =>
  api<AdminRestaurant[]>('/restaurants/manage/all');
export const createRestaurant = (body: CreateRestaurantInput) =>
  api<AdminRestaurant>('/restaurants', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateRestaurant = (id: string, body: UpdateRestaurantInput) =>
  api<AdminRestaurant>(`/restaurants/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const assignRestaurantOwner = (id: string, ownerUserId: string) =>
  api<AdminRestaurant>(`/restaurants/${id}/owner`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ownerUserId }),
  });
export const getPromos = () => api<PromoCode[]>('/admin/promos');
export const createPromo = (body: {
  code: string;
  type: 'PERCENT' | 'FIXED';
  value: number;
  minOrder: number;
}) =>
  api<PromoCode>('/admin/promos', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const togglePromo = (id: string, active: boolean) =>
  api<PromoCode>(`/admin/promos/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ active }),
  });
export const deletePromo = (id: string) =>
  api<unknown>(`/admin/promos/${id}`, { method: 'DELETE' });

export const getTariff = () => api<Tariff>('/admin/tariff');
export const updateTariff = (body: {
  deliveryFee: number;
  foodCommissionPercent: number;
  courierSharePercent: number;
  taxiBaseFare: number;
  taxiPerKm: number;
  taxiMinFare: number;
  taxiCommissionPercent: number;
  taxiWaitPerMin: number;
  parcelBaseFare: number;
  parcelPerKm: number;
  parcelMinFare: number;
  parcelCommissionPercent: number;
}) =>
  api<Tariff>('/admin/tariff', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

export const getPartners = (status?: string) =>
  api<PartnerApplication[]>(
    `/auth/admin/partners${status ? `?status=${status}` : ''}`,
  );
export const updatePartnerStatus = (
  id: string,
  status: 'APPROVED' | 'REJECTED',
) =>
  api<PartnerApplication>(`/auth/admin/partners/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status }),
  });

// ----- Geo (xizmat hududlari + joylar) -----
export const getGeoAreas = () => api<ServiceArea[]>('/admin/geo/areas');
export const createGeoArea = (body: CreateAreaInput) =>
  api<ServiceArea>('/admin/geo/areas', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateGeoArea = (id: string, body: { isActive?: boolean; name?: string }) =>
  api<ServiceArea>(`/admin/geo/areas/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteGeoArea = (id: string) =>
  api<unknown>(`/admin/geo/areas/${id}`, { method: 'DELETE' });
export const addGeoPlace = (
  areaId: string,
  body: { label: string; lat: number; lng: number; category?: string },
) =>
  api<GeoPlace>(`/admin/geo/areas/${areaId}/places`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteGeoPlace = (id: string) =>
  api<unknown>(`/admin/geo/places/${id}`, { method: 'DELETE' });

export function formatSom(value: number): string {
  return value.toLocaleString('ru-RU').replace(/ /g, ' ').replace(/,/g, ' ') + " so'm";
}

export function formatDate(iso: string): string {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString('ru-RU');
}
