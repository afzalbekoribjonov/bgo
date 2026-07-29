const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

const TOKEN_KEY = 'restaurant_token';
const RID_KEY = 'restaurant_id';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(RID_KEY);
}

export function setStoredRestaurantId(id: string): void {
  localStorage.setItem(RID_KEY, id);
}

export function getStoredRestaurantId(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(RID_KEY);
}

/** JWT payload (imzo tekshirilmaydi — faqat rol/restaurantId o'qish uchun). */
export function decodeToken(
  token: string,
): { sub?: string; roles?: string[]; restaurantId?: string } | null {
  try {
    const payload = token.split('.')[1];
    const json = atob(payload.replace(/-/g, '+').replace(/_/g, '/'));
    return JSON.parse(json);
  } catch {
    return null;
  }
}

/** Login/parol bilan kirish (sayt). Token + restaurantId saqlaydi. */
export async function kitchenLogin(
  username: string,
  password: string,
): Promise<{ restaurantId: string }> {
  const data = await post('/auth/kitchen/login', { username, password });
  setToken(data.accessToken);
  setStoredRestaurantId(data.restaurantId);
  return { restaurantId: data.restaurantId };
}

/**
 * Ilova (WebView) orqali kirish: URL'da ?token=... (yoki #token=...) bo'lsa
 * uni saqlaydi va URL'ni tozalaydi. Panelga avtomatik kirish.
 */
export function consumeUrlToken(): boolean {
  if (typeof window === 'undefined') return false;
  const url = new URL(window.location.href);
  const hash = new URLSearchParams(window.location.hash.replace(/^#/, ''));
  const token = url.searchParams.get('token') ?? hash.get('token');
  if (!token) return false;
  setToken(token);
  const decoded = decodeToken(token);
  if (decoded?.restaurantId) setStoredRestaurantId(decoded.restaurantId);
  // URL'ni tozalash (token ko'rinmasin).
  url.searchParams.delete('token');
  url.hash = '';
  window.history.replaceState({}, '', url.toString());
  return true;
}

interface AuthUser {
  id: string;
  phone: string;
  roles: string[];
}

async function post(path: string, body: unknown) {
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    throw new Error(data?.error?.message ?? data?.message ?? `Xatolik (${res.status})`);
  }
  return data.data;
}

export async function requestOtp(phone: string): Promise<string | undefined> {
  const data = await post('/auth/otp/request', { phone });
  return data?.devCode as string | undefined;
}

export async function verifyOtp(
  phone: string,
  code: string,
): Promise<{ accessToken: string; user: AuthUser }> {
  const data = await post('/auth/otp/verify', { phone, code });
  return { accessToken: data.accessToken, user: data.user };
}

export async function me(token: string): Promise<AuthUser> {
  const res = await fetch(`${BASE}/auth/me`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error('me failed');
  return (await res.json()).data as AuthUser;
}

export function isRestaurant(user: AuthUser): boolean {
  return user.roles.includes('restaurant') || user.roles.includes('admin');
}
