'use client';

import { useState } from 'react';
import { isAdmin, requestOtp, setRefreshToken, setToken, verifyOtp } from '@/lib/auth';

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
    if (!code || code.length < 4) {
      setError("Tasdiqlash kodi noto'g'ri");
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const { accessToken, refreshToken, user } = await verifyOtp(phone, code);
      if (!isAdmin(user)) {
        setError("Sizda admin huquqi yo'q");
        setLoading(false);
        return;
      }
      setToken(accessToken);
      setRefreshToken(refreshToken);
      onLoggedIn();
    } catch (e) {
      setError((e as Error).message);
      setLoading(false);
    }
  }

  function handlePhoneChange(v: string) {
    if (!v.startsWith('+998')) {
      setPhone('+998');
      return;
    }
    const digits = v.slice(4).replace(/\D/g, '').slice(0, 9);
    setPhone('+998' + digits);
  }

  return (
    <div className="login-page">
      <div className="login-card">
        {/* Logo */}
        <div className="login-logo">
          <div className="login-logo-icon">🍽️</div>
          <div className="login-brand">Beshariq</div>
          <div className="login-sub">Admin boshqaruv paneli</div>
        </div>

        {/* Step: phone */}
        {step === 'phone' && (
          <>
            <div style={{ marginBottom: 14 }}>
              <label>Telefon raqami</label>
              <input
                value={phone}
                onChange={(e) => handlePhoneChange(e.target.value)}
                placeholder="+998901234567"
                inputMode="tel"
                autoComplete="tel"
                style={{ fontSize: 16, letterSpacing: 0.5 }}
                onKeyDown={(e) => { if (e.key === 'Enter') send(); }}
              />
            </div>
            {error && (
              <div className="err-block" style={{ marginBottom: 12 }}>{error}</div>
            )}
            <button
              className="btn w-full"
              style={{ width: '100%', justifyContent: 'center', padding: '11px', fontSize: 14 }}
              disabled={loading || phone.length < 13}
              onClick={send}
            >
              {loading ? (
                <>
                  <span className="spinner" style={{ width: 16, height: 16, borderWidth: 2 }} />
                  Yuborilmoqda…
                </>
              ) : (
                'SMS kod yuborish'
              )}
            </button>
          </>
        )}

        {/* Step: OTP */}
        {step === 'otp' && (
          <>
            <p style={{ fontSize: 13, color: 'var(--text-3)', marginBottom: 14 }}>
              <strong>{phone}</strong> ga kod yuborildi.
            </p>
            <div style={{ marginBottom: 14 }}>
              <label>Tasdiqlash kodi</label>
              <input
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                placeholder="• • • • • •"
                inputMode="numeric"
                autoComplete="one-time-code"
                autoFocus
                style={{ fontSize: 22, letterSpacing: 8, textAlign: 'center' }}
                onKeyDown={(e) => { if (e.key === 'Enter') verify(); }}
              />
            </div>
            {devCode && (
              <div className="info-block blue" style={{ marginBottom: 12 }}>
                🧪 Sinov rejimi — kod: <strong>{devCode}</strong>
              </div>
            )}
            {error && (
              <div className="err-block" style={{ marginBottom: 12 }}>{error}</div>
            )}
            <button
              className="btn w-full"
              style={{ width: '100%', justifyContent: 'center', padding: '11px', fontSize: 14, marginBottom: 8 }}
              disabled={loading || code.length < 4}
              onClick={verify}
            >
              {loading ? (
                <>
                  <span className="spinner" style={{ width: 16, height: 16, borderWidth: 2 }} />
                  Tekshirilmoqda…
                </>
              ) : (
                'Kirish'
              )}
            </button>
            <button
              className="btn ghost w-full"
              style={{ width: '100%', justifyContent: 'center' }}
              onClick={() => {
                setStep('phone');
                setCode('');
                setError(null);
              }}
            >
              ← Orqaga
            </button>
          </>
        )}
      </div>
    </div>
  );
}
