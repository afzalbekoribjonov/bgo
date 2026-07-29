import { clearToken, getToken } from './auth';
import type {
  ChatMessage,
  ChatThread,
  Product,
  SellerProfile,
} from './types';

const BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

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
    clearToken();
    if (typeof window !== 'undefined') window.location.reload();
    throw new Error('Sessiya tugadi — qayta kiring');
  }
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    throw new Error(body?.error?.message ?? body?.message ?? `Xatolik (${res.status})`);
  }
  return body?.data as T;
}

export const getMyProducts = () => api<Product[]>('/marketplace/seller/products');
export const createProduct = (body: {
  categoryId?: string;
  name: { uz: string; uz_Cyrl?: string; ru?: string };
  description?: { uz: string; uz_Cyrl?: string; ru?: string };
  price: number;
  imageUrls?: string[];
  sizes?: string[];
  isActive?: boolean;
}) =>
  api<Product>('/marketplace/seller/products', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const updateProduct = (
  id: string,
  body: Partial<{
    categoryId: string;
    name: { uz: string; uz_Cyrl?: string; ru?: string };
    description: { uz: string; uz_Cyrl?: string; ru?: string };
    price: number;
    imageUrls: string[];
    sizes: string[];
    isActive: boolean;
  }>,
) =>
  api<Product>(`/marketplace/seller/products/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
export const deleteProduct = (id: string) =>
  api<unknown>(`/marketplace/seller/products/${id}`, { method: 'DELETE' });

export const getCategories = (sellerType: string) =>
  api<{ id: string; name: string; sortOrder: number }[]>(
    `/marketplace/categories?sellerType=${sellerType}`,
  ).catch(() => []);

export const getChatThreads = () => api<ChatThread[]>('/marketplace/seller/chats');
export const getChatMessages = (customerId: string) =>
  api<ChatMessage[]>(`/marketplace/seller/chats/${customerId}/messages`);
export const sendChatMessage = (customerId: string, text: string) =>
  api<ChatMessage>(`/marketplace/seller/chats/${customerId}/messages`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });

export const getProfile = () => api<SellerProfile>('/marketplace/seller/profile');
export const updateProfile = (body: {
  name?: string;
  description?: string;
  contactPhone?: string;
  address?: string;
  lat?: number;
  lng?: number;
}) =>
  api<SellerProfile>('/marketplace/seller/profile', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

/**
 * Rasmni serverga multipart yuklaydi. Server ImageKit sozlangan bo'lsa
 * CDN'ga, bo'lmasa lokal diskka saqlab, tayyor URL qaytaradi.
 */
export async function uploadProductImage(file: File): Promise<string> {
  const token = getToken();
  const form = new FormData();
  form.append('file', file);
  const res = await fetch(`${BASE}/marketplace/upload`, {
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

export function formatSom(value: number): string {
  return value.toLocaleString('ru-RU').replace(/,/g, ' ') + " so'm";
}

export function formatDate(iso: string): string {
  if (!iso) return '';
  return new Date(iso).toLocaleString('ru-RU');
}
