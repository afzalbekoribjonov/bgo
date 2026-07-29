const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

const TOKEN_KEY = 'seller_token';

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

/** JWT payload (imzo tekshirilmaydi — faqat rol/sellerId o'qish uchun). */
export function decodeToken(
  token: string,
): { sub?: string; roles?: string[]; sellerId?: string; sellerType?: string } | null {
  try {
    const payload = token.split('.')[1];
    const json = atob(payload.replace(/-/g, '+').replace(/_/g, '/'));
    return JSON.parse(json);
  } catch {
    return null;
  }
}

/** Login/parol bilan kirish. Token'ni saqlaydi va sellerId/sellerType qaytaradi. */
export async function sellerLogin(
  username: string,
  password: string,
): Promise<{ sellerId: string; sellerType: string }> {
  const res = await fetch(`${BASE}/auth/seller/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    throw new Error(data?.message ?? data?.error?.message ?? `Xatolik (${res.status})`);
  }
  setToken(data.data.accessToken);
  return { sellerId: data.data.sellerId, sellerType: data.data.sellerType };
}
