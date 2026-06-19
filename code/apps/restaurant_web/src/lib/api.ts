import type { Category, MenuItem, Order, Restaurant } from './types';

const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

async function api<T>(path: string, opts?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      'Accept-Language': 'uz',
      ...(opts?.headers ?? {}),
    },
    cache: 'no-store',
    ...opts,
  });
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

// Oshxona buyurtmalari (kitchen)
export const getKitchenOrders = (rid: string) =>
  api<Order[]>(`/kitchen/restaurants/${rid}/orders`);

export const orderAction = (
  id: string,
  action: 'accept' | 'preparing' | 'ready' | 'reject',
) => api<Order>(`/kitchen/orders/${id}/${action}`, { method: 'POST' });

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
  },
) =>
  api<MenuItem>(`/restaurants/${rid}/menu-items`, {
    method: 'POST',
    body: JSON.stringify(body),
  });

export const setAvailability = (rid: string, id: string, isAvailable: boolean) =>
  api<MenuItem>(`/restaurants/${rid}/menu-items/${id}/availability`, {
    method: 'PATCH',
    body: JSON.stringify({ isAvailable }),
  });

export const deleteMenuItem = (rid: string, id: string) =>
  api<unknown>(`/restaurants/${rid}/menu-items/${id}`, { method: 'DELETE' });

export function formatSom(value: number): string {
  return value.toLocaleString('ru-RU').replace(/,/g, ' ') + " so'm";
}
