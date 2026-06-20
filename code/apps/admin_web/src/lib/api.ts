import type { AdminOrder, Restaurant, Stats } from './types';
import { clearToken, getToken } from './auth';

const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

async function api<T>(path: string): Promise<T> {
  const token = getToken();
  const res = await fetch(`${BASE}${path}`, {
    cache: 'no-store',
    headers: token ? { Authorization: `Bearer ${token}` } : undefined,
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

export function formatSom(value: number): string {
  return value.toLocaleString('ru-RU').replace(/ /g, ' ').replace(/,/g, ' ') + " so'm";
}

export function formatDate(iso: string): string {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString('ru-RU');
}
