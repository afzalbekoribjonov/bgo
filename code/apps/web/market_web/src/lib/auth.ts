'use client';

const TOKEN_KEY = 'market_token';
const REFRESH_KEY = 'market_refresh_token';

/** Mijoz WebView orqali ochganda ?token= bilan keladi (customer_app'dagi joriy access token). */
export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return sessionStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  sessionStorage.setItem(TOKEN_KEY, token);
}

/** Access token muddati tugaganda /auth/refresh chaqirish uchun — ?refreshToken= bilan keladi. */
export function getRefreshToken(): string | null {
  if (typeof window === 'undefined') return null;
  return sessionStorage.getItem(REFRESH_KEY);
}

export function setRefreshToken(token: string): void {
  sessionStorage.setItem(REFRESH_KEY, token);
}

export function hasToken(): boolean {
  return !!getToken();
}

/**
 * URL'dagi ?token= (va ?refreshToken=) ni o'qib saqlaydi va manzildan
 * tozalaydi (restaurant_web dagi consumeUrlToken naqshi). Token bo'lmasa —
 * ko'rish rejimi (faqat katalog).
 */
export function consumeUrlToken(): void {
  if (typeof window === 'undefined') return;
  const params = new URLSearchParams(window.location.search);
  const token = params.get('token');
  const refreshToken = params.get('refreshToken');
  if (!token) return;
  setToken(token);
  if (refreshToken) setRefreshToken(refreshToken);
  params.delete('token');
  params.delete('refreshToken');
  const qs = params.toString();
  const cleanUrl = window.location.pathname + (qs ? `?${qs}` : '') + window.location.hash;
  window.history.replaceState({}, '', cleanUrl);
}
