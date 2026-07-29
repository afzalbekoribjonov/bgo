'use client';

import { useState } from 'react';
import { clearToken } from '@/lib/auth';
import { updateRestaurantLogo, uploadRestaurantLogo } from '@/lib/api';
import ImageUploader from '@/components/image-uploader';
import { useRestaurant } from '../restaurant-provider';

function LogoSection() {
  const { restaurant, refresh } = useRestaurant();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  async function handleChange(url: string | null) {
    if (!url || !restaurant) return;
    setSaving(true);
    setError('');
    try {
      await updateRestaurantLogo(restaurant.id, url);
      await refresh();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="card">
      <div className="sec-title">Oshxona logotipi</div>
      <ImageUploader
        value={restaurant?.logoUrl ?? null}
        onChange={handleChange}
        upload={uploadRestaurantLogo}
        label="Logotip (oshxona rasmi)"
        shape="circle"
      />
      {saving && (
        <div className="muted" style={{ fontSize: 12, textAlign: 'center' }}>
          Saqlanmoqda…
        </div>
      )}
      {error && (
        <div
          style={{
            color: 'var(--red)',
            fontSize: 12.5,
            fontWeight: 600,
            textAlign: 'center',
          }}
        >
          ⚠ {error}
        </div>
      )}
    </div>
  );
}

function StarRating({ rating }: { rating: number }) {
  return (
    <div style={{ display: 'flex', gap: 2, alignItems: 'center' }}>
      {[1, 2, 3, 4, 5].map((i) => (
        <span
          key={i}
          style={{
            fontSize: 18,
            color: i <= Math.round(rating) ? 'var(--gold)' : 'var(--border)',
          }}
        >
          ★
        </span>
      ))}
      <span
        style={{ marginLeft: 6, fontWeight: 700, fontSize: 15, color: 'var(--text)' }}
      >
        {rating > 0 ? rating.toFixed(1) : 'Baholanmagan'}
      </span>
    </div>
  );
}

export default function SettingsPage() {
  const { restaurant, busy, toggle } = useRestaurant();

  function logout() {
    clearToken();
    window.location.href = '/login';
  }

  if (!restaurant) {
    return (
      <div className="container">
        <p className="muted" style={{ textAlign: 'center', padding: '48px 0' }}>
          Yuklanmoqda…
        </p>
      </div>
    );
  }

  return (
    <div className="container" style={{ paddingBottom: 32 }}>
      <h2 className="big" style={{ marginBottom: 16, marginTop: 4 }}>
        Sozlamalar
      </h2>

      <LogoSection />

      {/* Oshxona holati */}
      <div className="card">
        <div className="sec-title">Oshxona holati</div>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 16,
            padding: '8px 0',
          }}
        >
          <div>
            <div
              style={{
                fontSize: 18,
                fontWeight: 900,
                color: restaurant.isOpen ? 'var(--green)' : 'var(--red)',
                letterSpacing: 0.4,
              }}
            >
              {restaurant.isOpen ? '● OCHIQ' : '● YOPIQ'}
            </div>
            <div className="muted" style={{ fontSize: 13, marginTop: 2 }}>
              {restaurant.isOpen
                ? 'Buyurtmalar qabul qilinmoqda'
                : 'Buyurtmalar kelmaydi'}
            </div>
          </div>

          <button
            className={`btn ${restaurant.isOpen ? 'red' : 'green'}`}
            onClick={toggle}
            disabled={busy}
            style={{ minWidth: 110 }}
          >
            {busy
              ? '…'
              : restaurant.isOpen
              ? 'Yopish'
              : 'Ochish'}
          </button>
        </div>
      </div>

      {/* Oshxona ma'lumotlari */}
      <div className="card">
        <div className="sec-title">Oshxona haqida</div>

        <div style={{ display: 'grid', gap: 14 }}>
          <div>
            <label>Nomi</label>
            <div
              style={{
                padding: '11px 13px',
                border: '1.5px solid var(--border)',
                borderRadius: 12,
                fontSize: 15,
                background: '#f8fafc',
                color: 'var(--text)',
              }}
            >
              {restaurant.name}
            </div>
          </div>

          <div>
            <label>Manzil</label>
            <div
              style={{
                padding: '11px 13px',
                border: '1.5px solid var(--border)',
                borderRadius: 12,
                fontSize: 15,
                background: '#f8fafc',
                color: 'var(--text)',
              }}
            >
              {restaurant.address || '—'}
            </div>
          </div>

          <div>
            <label>Reyting</label>
            <div style={{ marginTop: 6 }}>
              <StarRating rating={restaurant.rating ?? 0} />
            </div>
          </div>
        </div>

        <div
          style={{
            marginTop: 14,
            padding: '10px 14px',
            background: 'rgba(31,111,235,0.06)',
            borderRadius: 12,
            fontSize: 13,
            color: 'var(--muted)',
          }}
        >
          ℹ Oshxona nomini va manzilini o&apos;zgartirish uchun admin bilan
          bog&apos;laning
        </div>
      </div>

      {/* Chiqish */}
      <div className="card">
        <div className="sec-title">Hisob</div>
        <button
          className="btn red block"
          onClick={logout}
          style={{ marginTop: 0 }}
        >
          Chiqish (logout)
        </button>
      </div>
    </div>
  );
}
