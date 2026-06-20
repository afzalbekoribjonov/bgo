const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

const TOKEN_KEY = 'restaurant_token';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY);
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
