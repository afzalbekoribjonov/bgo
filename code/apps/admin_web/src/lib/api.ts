import type { AdminOrder, PromoCode, Restaurant, Stats, Tariff } from './types';
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
export const getOrders = (status?: string) =>
  api<AdminOrder[]>(`/admin/orders${status ? `?status=${status}` : ''}`);
export const getRestaurants = () => api<Restaurant[]>('/restaurants');
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
}) =>
  api<Tariff>('/admin/tariff', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

export function formatSom(value: number): string {
  return value.toLocaleString('ru-RU').replace(/ /g, ' ').replace(/,/g, ' ') + " so'm";
}

export function formatDate(iso: string): string {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString('ru-RU');
}
