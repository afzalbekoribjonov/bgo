import { getRefreshToken, getToken, setRefreshToken, setToken } from './auth';
import type {
  Category,
  MarketSettings,
  PagedResult,
  PickupLocation,
  Product,
  ProductComment,
  StoreOrder,
  SupportMessage,
} from './types';

const BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

/**
 * Access token muddati tugaganda (30 daqiqa) qayta login so'ralmasin uchun
 * — saqlangan refresh token bilan yangi juftlik olinadi. Bir nechta so'rov
 * bir vaqtda 401 olsa ham refresh FAQAT bir marta chaqirilishi uchun
 * natija promise sifatida keshlanadi.
 */
let refreshInFlight: Promise<string | null> | null = null;
function refreshAccessToken(): Promise<string | null> {
  if (refreshInFlight) return refreshInFlight;
  const refreshToken = getRefreshToken();
  if (!refreshToken) return Promise.resolve(null);
  refreshInFlight = fetch(`${BASE}/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
  })
    .then((res) => (res.ok ? res.json() : null))
    .then((body) => {
      const access = body?.data?.accessToken as string | undefined;
      const refresh = body?.data?.refreshToken as string | undefined;
      if (!access || !refresh) return null;
      setToken(access);
      setRefreshToken(refresh);
      return access;
    })
    .catch(() => null)
    .finally(() => {
      refreshInFlight = null;
    });
  return refreshInFlight;
}

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
  if (res.status === 401 && token) {
    const fresh = await refreshAccessToken();
    if (fresh) {
      const retryRes = await fetch(`${BASE}${path}`, {
        cache: 'no-store',
        ...opts,
        headers: {
          Authorization: `Bearer ${fresh}`,
          ...(opts?.headers ?? {}),
        },
      });
      const retryBody = await retryRes.json().catch(() => null);
      if (!retryRes.ok) {
        throw new Error(retryBody?.error?.message ?? retryBody?.message ?? `Xatolik (${retryRes.status})`);
      }
      return retryBody?.data as T;
    }
  }
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    throw new Error(body?.error?.message ?? body?.message ?? `Xatolik (${res.status})`);
  }
  return body?.data as T;
}

export const getCategories = () => api<Category[]>('/market/categories');
export const getProducts = (query: {
  categoryId?: string;
  q?: string;
  page?: number;
  pageSize?: number;
} = {}) => {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value) params.set(key, String(value));
  }
  const qs = params.toString();
  return api<PagedResult<Product>>(`/market/products${qs ? `?${qs}` : ''}`);
};
export const getMarketSettings = () => api<MarketSettings>('/market/settings');
export const getProduct = (id: string) => api<Product>(`/market/products/${id}`);
export const likeProduct = (id: string) =>
  api<{ likesCount: number; liked: boolean }>(`/market/products/${id}/like`, { method: 'POST' });
export const getComments = (id: string) => api<ProductComment[]>(`/market/products/${id}/comments`);
export const addComment = (id: string, text: string) =>
  api<ProductComment>(`/market/products/${id}/comments`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });
export const getPickupLocations = () => api<PickupLocation[]>('/market/pickup-locations');

export const createOrder = (body: {
  pickupLocationId: string;
  deliveryMethod: 'DELIVERY' | 'PICKUP';
  address?: { text: string; lat: number; lng: number };
  items: { productId: string; qty: number; size?: string }[];
}) =>
  api<StoreOrder>('/store/orders', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const getMyOrders = () => api<StoreOrder[]>('/store/orders/mine');
export const getOrder = (id: string) => api<StoreOrder>(`/store/orders/${id}`);
export const cancelOrder = (id: string) =>
  api<StoreOrder>(`/store/orders/${id}/cancel`, { method: 'POST' });
export const rateOrder = (id: string, rating: number, comment?: string) =>
  api<StoreOrder>(`/store/orders/${id}/rate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ rating, comment }),
  });

export const getSupportMessages = () => api<SupportMessage[]>('/market/support/messages');
export const sendSupportMessage = (text: string) =>
  api<SupportMessage>('/market/support/messages', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });

export function formatSom(value: number): string {
  return value.toLocaleString('ru-RU').replace(/,/g, ' ') + " so'm";
}

export function formatDate(iso: string): string {
  if (!iso) return '';
  return new Date(iso).toLocaleString('ru-RU');
}

/** Nisbiy vaqt (izohlar uchun) — 7 kundan eskisi to'liq sanaga qaytadi. */
export function timeAgo(iso: string): string {
  const sec = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (sec < 60) return 'hozir';
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min} daqiqa oldin`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${hr} soat oldin`;
  const day = Math.floor(hr / 24);
  if (day === 1) return 'kecha';
  if (day < 7) return `${day} kun oldin`;
  return formatDate(iso);
}
