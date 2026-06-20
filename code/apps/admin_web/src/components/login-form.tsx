'use client';

import { useState } from 'react';
import { isAdmin, requestOtp, setToken, verifyOtp } from '@/lib/auth';

export default function LoginForm({ onLoggedIn }: { onLoggedIn: () => void }) {
  const [phone, setPhone] = useState('+998');
  const [code, setCode] = useState('');
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [devCode, setDevCode] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function send() {
    if (!/^\+998\d{9}$/.test(phone)) {
      setError("Telefon raqami noto'g'ri (+998XXXXXXXXX)");
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const dc = await requestOtp(phone);
      setDevCode(dc);
      setStep('otp');
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }

  async function verify() {
    setLoading(true);
    setError(null);
    try {
      const { accessToken, user } = await verifyOtp(phone, code);
      if (!isAdmin(user)) {
        setError("Sizda admin huquqi yo'q");
        setLoading(false);
        return;
      }
      setToken(accessToken);
      onLoggedIn();
    } catch (e) {
      setError((e as Error).message);
      setLoading(false);
    }
  }

  return (
    <div className="container" style={{ maxWidth: 420 }}>
      <div className="card">
        <div className="title" style={{ marginBottom: 12 }}>
          Admin kirishi
        </div>
        {step === 'phone' ? (
          <>
            <label>Telefon raqami</label>
            <input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+998901234567"
            />
            {error && <p className="error">{error}</p>}
            <button
              className="btn"
              style={{ marginTop: 12 }}
              disabled={loading}
              onClick={send}
            >
              {loading ? '...' : 'Kod yuborish'}
            </button>
          </>
        ) : (
          <>
            <label>Tasdiqlash kodi</label>
            <input
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/[^0-9]/g, ''))}
              placeholder="______"
              inputMode="numeric"
            />
            {devCode && (
              <p className="muted" style={{ marginTop: 6 }}>
                Sinov rejimi — kod: <b>{devCode}</b>
              </p>
            )}
            {error && <p className="error">{error}</p>}
            <button
              className="btn"
              style={{ marginTop: 12 }}
              disabled={loading}
              onClick={verify}
            >
              {loading ? '...' : 'Kirish'}
            </button>
            <button
              className="btn ghost"
              style={{ marginTop: 8 }}
              onClick={() => {
                setStep('phone');
                setCode('');
                setError(null);
              }}
            >
              Orqaga
            </button>
          </>
        )}
      </div>
    </div>
  );
}
