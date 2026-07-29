'use client';

import { useState } from 'react';
import { sellerLogin } from '@/lib/auth';
import { useAuthState } from '@/lib/auth-context';
import BottomNav from './bottom-nav';

export default function AuthGate({ children }: { children: React.ReactNode }) {
  const { ready, authed, refresh } = useAuthState();

  if (!ready) {
    return (
      <div className="loading-page">
        <div className="spinner" />
      </div>
    );
  }

  if (!authed) {
    return <LoginForm onLoggedIn={refresh} />;
  }

  return (
    <div className="app">
      {children}
      <BottomNav />
    </div>
  );
}

function LoginForm({ onLoggedIn }: { onLoggedIn: () => void }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr('');
    if (!username.trim() || !password) {
      setErr('Login va parolni kiriting');
      return;
    }
    setBusy(true);
    try {
      await sellerLogin(username.trim(), password);
      onLoggedIn();
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="login-page">
      <div className="login-logo">🏪</div>
      <div className="login-title">Sotuvchi paneli</div>
      <div className="login-sub">Do'konlar / Qurilishda foydali</div>

      <form onSubmit={submit}>
        <div className="field">
          <label>Login</label>
          <input
            value={username}
            autoComplete="username"
            onChange={(e) => setUsername(e.target.value)}
            placeholder="login"
          />
        </div>
        <div className="field">
          <label>Parol</label>
          <input
            value={password}
            type="password"
            autoComplete="current-password"
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••"
          />
        </div>
        {err && <div className="err-block">{err}</div>}
        <button className="btn btn-block" disabled={busy} type="submit">
          {busy ? 'Kirilmoqda…' : 'Kirish'}
        </button>
      </form>
    </div>
  );
}
