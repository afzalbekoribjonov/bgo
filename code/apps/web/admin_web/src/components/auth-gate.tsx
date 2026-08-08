'use client';

import { useCallback, useEffect, useState } from 'react';
import { clearToken, getToken, isAdmin, me, refreshAccessToken } from '@/lib/auth';
import LoginForm from './login-form';
import Nav from '@/app/nav';

export default function AuthGate({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<'loading' | 'in' | 'out'>('loading');

  const check = useCallback(async () => {
    let token = getToken();
    if (!token) {
      setState('out');
      return;
    }
    try {
      const user = await me(token);
      if (isAdmin(user)) {
        setState('in');
      } else {
        clearToken();
        setState('out');
      }
    } catch {
      // Panel qayta ochilganda access token allaqachon muddati tugagan
      // bo'lishi mumkin (30 daqiqa) — darhol chiqarib yubormasdan, avval
      // saqlangan refresh token bilan sokin urinib ko'ramiz.
      token = await refreshAccessToken();
      if (!token) {
        clearToken();
        setState('out');
        return;
      }
      try {
        const user = await me(token);
        if (isAdmin(user)) {
          setState('in');
        } else {
          clearToken();
          setState('out');
        }
      } catch {
        clearToken();
        setState('out');
      }
    }
  }, []);

  useEffect(() => {
    check();
  }, [check]);

  function logout() {
    clearToken();
    setState('out');
  }

  if (state === 'loading') {
    return (
      <div className="loading-page">
        <div className="spinner" />
        <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>Yuklanmoqda…</span>
      </div>
    );
  }

  if (state === 'out') {
    return <LoginForm onLoggedIn={check} />;
  }

  return (
    <div className="layout">
      <Nav onLogout={logout} />
      <div className="main">
        {children}
      </div>
    </div>
  );
}
