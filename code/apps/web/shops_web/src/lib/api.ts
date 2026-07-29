import { getToken } from './auth';
import type { Category, ChatMessage, ChatThread, Product, SellerProfile, SellerType } from './types';

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
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    throw new Error(body?.error?.message ?? body?.message ?? `Xatolik (${res.status})`);
  }
  return body?.data as T;
}

export const getCategories = (sellerType: SellerType) =>
  api<Category[]>(`/marketplace/categories?sellerType=${sellerType}`);
export const getProducts = (
  sellerType: SellerType,
  opts?: { categoryId?: string; near?: { lat: number; lng: number } },
) =>
  api<Product[]>(
    `/marketplace/products?sellerType=${sellerType}` +
      (opts?.categoryId ? `&categoryId=${opts.categoryId}` : '') +
      // Joylashuv berilsa server eng yaqin do'kon mahsulotlarini birinchi qaytaradi
      (opts?.near ? `&lat=${opts.near.lat}&lng=${opts.near.lng}` : ''),
  );
export const getProduct = (id: string) => api<Product>(`/marketplace/products/${id}`);
export const getSeller = (id: string) => api<SellerProfile>(`/marketplace/sellers/${id}`);

export const getChatThreads = () => api<ChatThread[]>('/marketplace/chat/threads');
export const getChatMessages = (sellerId: string) =>
  api<ChatMessage[]>(`/marketplace/chat/${sellerId}/messages`);
export const sendChatMessage = (sellerId: string, text: string) =>
  api<ChatMessage>(`/marketplace/chat/${sellerId}/messages`, {
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
