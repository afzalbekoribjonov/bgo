'use client';

import { useCallback, useEffect, useState } from 'react';
import { clearToken, getToken, isRestaurant, me } from '@/lib/auth';
import LoginForm from './login-form';

/** restaurant_web himoyasi: faqat 'restaurant' (yoki admin) roli kira oladi. */
export default function AuthGate({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<'loading' | 'in' | 'out'>('loading');

  const check = useCallback(async () => {
    const token = getToken();
    if (!token) {
      setState('out');
      return;
    }
    try {
      const user = await me(token);
      if (isRestaurant(user)) {
        setState('in');
      } else {
        clearToken();
        setState('out');
      }
    } catch {
      clearToken();
      setState('out');
    }
  }, []);

  useEffect(() => {
    check();
  }, [check]);

  if (state === 'loading') {
    return (
      <div className="container">
        <p className="muted">Yuklanmoqda…</p>
      </div>
    );
  }

  if (state === 'out') {
    return <LoginForm onLoggedIn={check} />;
  }

  return (
    <>
      <div style={{ textAlign: 'right', padding: '8px 20px' }}>
        <button
          className="btn ghost"
          onClick={() => {
            clearToken();
            setState('out');
          }}
        >
          Chiqish
        </button>
      </div>
      {children}
    </>
  );
}
