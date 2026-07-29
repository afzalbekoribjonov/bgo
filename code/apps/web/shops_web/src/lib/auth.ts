'use client';

const TOKEN_KEY = 'shops_token';

/** Mijoz WebView orqali ochganda ?token= bilan keladi (customer_app'dagi joriy access token). */
export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return sessionStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  sessionStorage.setItem(TOKEN_KEY, token);
}

export function hasToken(): boolean {
  return !!getToken();
}

/**
 * URL'dagi ?token= ni o'qib saqlaydi va manzildan tozalaydi. Token bo'lmasa
 * — ko'rish rejimi (faqat katalog, chat/aloqa uchun ilovadan ochish kerak).
 */
export function consumeUrlToken(): void {
  if (typeof window === 'undefined') return;
  const params = new URLSearchParams(window.location.search);
  const token = params.get('token');
  if (!token) return;
  setToken(token);
  params.delete('token');
  const qs = params.toString();
  const cleanUrl = window.location.pathname + (qs ? `?${qs}` : '') + window.location.hash;
  window.history.replaceState({}, '', cleanUrl);
}
