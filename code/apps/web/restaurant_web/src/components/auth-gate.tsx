'use client';

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  clearToken,
  consumeUrlToken,
  decodeToken,
  getStoredRestaurantId,
  getToken,
} from '@/lib/auth';
import LoginForm from './login-form';

/**
 * Panel himoyasi: login/parol (sayt) yoki ?token= (ilova WebView).
 * Token client-side dekodlanadi (role 'restaurant' + restaurantId).
 */
export default function AuthGate({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<'loading' | 'in' | 'out'>('loading');
  const router = useRouter();

  const check = useCallback(() => {
    // Ilova WebView orqali kirish (URL'dagi token).
    consumeUrlToken();
    const token = getToken();
    if (!token) {
      setState('out');
      return;
    }
    const decoded = decodeToken(token);
    const ok =
      !!decoded &&
      (decoded.roles?.includes('restaurant') ||
        decoded.roles?.includes('admin'));
    if (!ok) {
      clearToken();
      setState('out');
      return;
    }
    setState('in');
    // To'g'ridan-to'g'ri o'z oshxonasiga (login/webview restaurantId'ni biladi).
    const rid = decoded?.restaurantId ?? getStoredRestaurantId();
    if (rid && window.location.pathname === '/') {
      router.replace(`/restaurants/${rid}/orders`);
    }
  }, [router]);

  useEffect(() => {
    check();
  }, [check]);

  if (state === 'loading') {
    return (
      <div className="center-screen">
        <p className="muted">Yuklanmoqda…</p>
      </div>
    );
  }

  if (state === 'out') {
    return <LoginForm onLoggedIn={check} />;
  }

  return <>{children}</>;
}
