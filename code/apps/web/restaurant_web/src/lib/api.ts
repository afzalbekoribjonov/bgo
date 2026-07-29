import type { Category, KitchenStats, MenuItem, Order, OrderMessage, Restaurant } from './types';
import { clearToken, getToken } from './auth';

const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

async function api<T>(path: string, opts?: RequestInit): Promise<T> {
  const token = getToken();
  const res = await fetch(`${BASE}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      'Accept-Language': 'uz',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(opts?.headers ?? {}),
    },
    cache: 'no-store',
    ...opts,
  });
  if (res.status === 401 || res.status === 403) {
    clearToken();
    if (typeof window !== 'undefined') window.location.reload();
    throw new Error('Avtorizatsiya talab qilinadi');
  }
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    const message =
      body?.error?.message ?? body?.message ?? `Xatolik (${res.status})`;
    throw new Error(Array.isArray(message) ? message.join(', ') : message);
  }
  return body?.data as T;
}

// Katalog
export const getRestaurants = () => api<Restaurant[]>('/restaurants');
export const getRestaurant = (id: string) => api<Restaurant>(`/restaurants/${id}`);
/** Joriy foydalanuvchining (egalik) oshxonalari. */
export const getMyRestaurants = () => api<Restaurant[]>('/restaurants/mine');

// Oshxona buyurtmalari (kitchen)
export const getKitchenOrders = (rid: string) =>
  api<Order[]>(`/kitchen/restaurants/${rid}/orders`);

export const getKitchenHistory = (rid: string) =>
  api<Order[]>(`/kitchen/restaurants/${rid}/orders/history`);

export const getKitchenStats = (rid: string) =>
  api<KitchenStats>(`/kitchen/restaurants/${rid}/stats`);

export const orderAction = (
  id: string,
  action: 'accept' | 'preparing' | 'ready' | 'reject',
) => api<Order>(`/kitchen/orders/${id}/${action}`, { method: 'POST' });

// Oshxona holati (ochiq/yopiq)
export const setRestaurantOpen = (rid: string, isOpen: boolean) =>
  api<Restaurant>(`/restaurants/${rid}/open`, {
    method: 'PATCH',
    body: JSON.stringify({ isOpen }),
  });

export const updateRestaurantLogo = (rid: string, logoUrl: string) =>
  api<Restaurant>(`/restaurants/${rid}/logo`, {
    method: 'PATCH',
    body: JSON.stringify({ logoUrl }),
  });

// Oshxona↔haydovchi suhbat
export const getOrderMessages = (id: string) =>
  api<OrderMessage[]>(`/kitchen/orders/${id}/messages`);

export const sendOrderMessage = (id: string, text: string) =>
  api<OrderMessage>(`/kitchen/orders/${id}/messages`, {
    method: 'POST',
    body: JSON.stringify({ text }),
  });

// Menyu boshqaruvi
export const getCategories = (rid: string) =>
  api<Category[]>(`/restaurants/${rid}/categories`);

export const getMenuItems = (rid: string) =>
  api<MenuItem[]>(`/restaurants/${rid}/menu-items`);

export const createCategory = (
  rid: string,
  body: { name: { uz: string; uz_Cyrl?: string; ru?: string }; sortOrder?: number },
) =>
  api<Category>(`/restaurants/${rid}/categories`, {
    method: 'POST',
    body: JSON.stringify(body),
  });

export const createMenuItem = (
  rid: string,
  body: {
    categoryId: string;
    name: { uz: string; uz_Cyrl?: string; ru?: string };
    price: number;
    imageUrl?: string;
  },
) =>
  api<MenuItem>(`/restaurants/${rid}/menu-items`, {
    method: 'POST',
    body: JSON.stringify(body),
  });

export const updateMenuItem = (
  rid: string,
  id: string,
  body: {
    categoryId?: string;
    name?: { uz: string; uz_Cyrl?: string; ru?: string };
    price?: number;
    imageUrl?: string;
  },
) =>
  api<MenuItem>(`/restaurants/${rid}/menu-items/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  });

/** Taom rasmini serverga multipart yuklaydi va tayyor URL qaytaradi. */
export async function uploadMenuItemImage(file: File): Promise<string> {
  const token = getToken();
  const form = new FormData();
  form.append('file', file);
  const res = await fetch(`${BASE}/restaurants/upload`, {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: form,
  });
  const body = await res.json().catch(() => null);
  if (!res.ok || !body?.success) {
    throw new Error(body?.error?.message ?? body?.message ?? 'Rasm yuklashda xatolik');
  }
  return body.data.url as string;
}

/** Xuddi shu umumiy `/restaurants/upload` endpoint — logotip uchun aniqroq nom. */
export const uploadRestaurantLogo = uploadMenuItemImage;

export const setAvailability = (rid: string, id: string, isAvailable: boolean) =>
  api<MenuItem>(`/restaurants/${rid}/menu-items/${id}/availability`, {
    method: 'PATCH',
    body: JSON.stringify({ isAvailable }),
  });

export const deleteMenuItem = (rid: string, id: string) =>
  api<unknown>(`/restaurants/${rid}/menu-items/${id}`, { method: 'DELETE' });

export const updateCategory = (
  rid: string,
  id: string,
  body: { name?: { uz: string; uz_Cyrl?: string; ru?: string }; sortOrder?: number },
) =>
  api<Category>(`/restaurants/${rid}/categories/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  });

export const deleteCategory = (rid: string, id: string) =>
  api<unknown>(`/restaurants/${rid}/categories/${id}`, { method: 'DELETE' });

export function formatSom(value: number): string {
  return value.toLocaleString('ru-RU').replace(/,/g, ' ') + " so'm";
}
