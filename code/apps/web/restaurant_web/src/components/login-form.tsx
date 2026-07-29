'use client';

import { useState } from 'react';
import { kitchenLogin } from '@/lib/auth';

export default function LoginForm({ onLoggedIn }: { onLoggedIn: () => void }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!username.trim() || !password) {
      setError('Login va parolni kiriting');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await kitchenLogin(username.trim(), password);
      onLoggedIn();
    } catch (e) {
      setError((e as Error).message);
      setLoading(false);
    }
  }

  return (
    <div className="auth-wrap">
      <form className="auth-card" onSubmit={submit}>
        <div className="auth-logo">🍽️</div>
        <div className="auth-title">Oshxona paneli</div>
        <div className="auth-sub">Login va parol bilan kiring</div>

        <label className="field-label">Login</label>
        <input
          className="field"
          value={username}
          autoCapitalize="none"
          autoComplete="username"
          onChange={(e) => setUsername(e.target.value)}
          placeholder="oshxona_login"
        />

        <label className="field-label">Parol</label>
        <input
          className="field"
          type="password"
          value={password}
          autoComplete="current-password"
          onChange={(e) => setPassword(e.target.value)}
          placeholder="••••••••"
        />

        {error && <p className="error">{error}</p>}

        <button className="btn primary block" disabled={loading} type="submit">
          {loading ? 'Kirilmoqda…' : 'Kirish'}
        </button>
        <p className="auth-hint">
          Login/parolni administrator beradi. Ilova orqali kirsangiz — avtomatik.
        </p>
      </form>
    </div>
  );
}
