const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

const TOKEN_KEY = 'admin_token';
const REFRESH_KEY = 'admin_refresh_token';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token);
}

/** Access token muddati tugaganda (30 daqiqa) qayta login so'ralmasligi uchun. */
export function getRefreshToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(REFRESH_KEY);
}

export function setRefreshToken(token: string): void {
  localStorage.setItem(REFRESH_KEY, token);
}

export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
}

/**
 * Access token muddati tugaganda (30 daqiqa) admin qayta login qilishga
 * majburlanmasin — saqlangan refresh token bilan yangi juftlik olinadi.
 * Bir nechta joy (api.ts, auth-gate.tsx) bir vaqtda chaqirsa ham refresh
 * FAQAT bir marta bajarilishi uchun natija promise sifatida keshlanadi.
 * Muvaffaqiyatli bo'lsa yangi access token qaytadi va storage yangilanadi;
 * aks holda (refresh tokeni ham amal qilmasa) `null`.
 */
let refreshInFlight: Promise<string | null> | null = null;
export function refreshAccessToken(): Promise<string | null> {
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

/** OTP so'rash. Dev rejimda devCode qaytishi mumkin. */
export async function requestOtp(phone: string): Promise<string | undefined> {
  const data = await post('/auth/otp/request', { phone });
  return data?.devCode as string | undefined;
}

/** OTP tasdiqlash → { accessToken, refreshToken, user }. */
export async function verifyOtp(
  phone: string,
  code: string,
): Promise<{ accessToken: string; refreshToken: string; user: AuthUser }> {
  const data = await post('/auth/otp/verify', { phone, code });
  return { accessToken: data.accessToken, refreshToken: data.refreshToken, user: data.user };
}

/** Joriy foydalanuvchi (token bilan) — sessiyani tekshirish uchun. */
export async function me(token: string): Promise<AuthUser> {
  const res = await fetch(`${BASE}/auth/me`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error('me failed');
  return (await res.json()).data as AuthUser;
}

export function isAdmin(user: AuthUser): boolean {
  return user.roles.includes('admin') || user.roles.includes('super_admin');
}
