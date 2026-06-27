'use client';

import dynamic from 'next/dynamic';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import {
  assignRestaurantOwner,
  formatSom,
  getManageRestaurants,
  getRestaurantMenu,
  updateRestaurant,
} from '@/lib/api';
import type { AdminRestaurant, RestaurantMenuView } from '@/lib/types';

const LocationMap = dynamic(() => import('@/components/location-map'), {
  ssr: false,
  loading: () => (
    <div
      style={{
        height: 360,
        background: 'var(--card)',
        border: '1px solid var(--border)',
        borderRadius: 12,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'var(--muted)',
      }}
    >
      Xarita yuklanmoqda…
    </div>
  ),
});

const STATUSES = ['ACTIVE', 'PENDING', 'BLOCKED'] as const;
const STATUS_LABEL: Record<string, string> = {
  ACTIVE: 'Faol',
  PENDING: 'Kutilmoqda',
  BLOCKED: 'Bloklangan',
};

export default function RestaurantDetailPage() {
  const params = useParams<{ id: string }>();
  const id = params.id;

  const [r, setR] = useState<AdminRestaurant | null>(null);
  const [menu, setMenu] = useState<RestaurantMenuView | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [savedMsg, setSavedMsg] = useState(false);

  // Tahrirlanadigan maydonlar
  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [commission, setCommission] = useState('0');
  const [status, setStatus] = useState<AdminRestaurant['status']>('ACTIVE');
  const [isOpen, setIsOpen] = useState(true);
  const [lat, setLat] = useState(0);
  const [lng, setLng] = useState(0);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [all, m] = await Promise.all([
        getManageRestaurants(),
        getRestaurantMenu(id).catch(() => null),
      ]);
      const found = all.find((x) => x.id === id) ?? null;
      setR(found);
      setMenu(m);
      if (found) {
        setName(found.name);
        setAddress(found.address);
        setPhone(found.phone);
        setCommission(String(found.commissionPercent));
        setStatus(found.status);
        setIsOpen(found.isOpen);
        setLat(found.lat);
        setLng(found.lng);
      }
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  async function save() {
    setSaving(true);
    setError(null);
    try {
      await updateRestaurant(id, {
        name: name.trim(),
        address: address.trim(),
        phone: phone.trim(),
        commissionPercent: parseInt(commission, 10) || 0,
        status,
        isOpen,
        lat,
        lng,
      });
      setSavedMsg(true);
      setTimeout(() => setSavedMsg(false), 2500);
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function assignOwner() {
    if (!r) return;
    const ownerUserId = window.prompt(
      `"${r.name}" egasining foydalanuvchi ID'si:`,
      r.ownerUserId ?? '',
    );
    if (!ownerUserId) return;
    try {
      await assignRestaurantOwner(id, ownerUserId.trim());
      await load();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  if (loading) {
    return (
      <div className="container">
        <p className="muted">Yuklanmoqda…</p>
      </div>
    );
  }
  if (!r) {
    return (
      <div className="container">
        <Link href="/restaurants" className="btn ghost">
          ← Oshxonalar
        </Link>
        <p className="error" style={{ marginTop: 12 }}>
          Oshxona topilmadi
        </p>
      </div>
    );
  }

  const itemCount =
    menu?.categories.reduce((s, c) => s + c.items.length, 0) ?? 0;

  return (
    <div className="container">
      <Link href="/restaurants" className="btn ghost" style={{ marginBottom: 12 }}>
        ← Oshxonalar ro&apos;yxati
      </Link>
      <h1 className="h1" style={{ marginTop: 8 }}>
        {r.name}
      </h1>
      {error && <p className="error">{error}</p>}
      {savedMsg && (
        <p style={{ color: 'var(--green)', fontWeight: 600 }}>✓ Saqlandi</p>
      )}

      {/* Asosiy ma'lumotlar */}
      <div className="card" style={{ marginBottom: 16 }}>
        <strong>Asosiy ma&apos;lumotlar</strong>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: 12,
            marginTop: 12,
          }}
        >
          <div>
            <label>Nomi</label>
            <input value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div>
            <label>Manzil (matn)</label>
            <input value={address} onChange={(e) => setAddress(e.target.value)} />
          </div>
          <div>
            <label>Telefon</label>
            <input value={phone} onChange={(e) => setPhone(e.target.value)} />
          </div>
          <div>
            <label>Komissiya %</label>
            <input
              value={commission}
              inputMode="numeric"
              onChange={(e) =>
                setCommission(e.target.value.replace(/[^0-9]/g, ''))
              }
            />
          </div>
          <div>
            <label>Holat</label>
            <select
              value={status}
              onChange={(e) =>
                setStatus(e.target.value as AdminRestaurant['status'])
              }
            >
              {STATUSES.map((s) => (
                <option key={s} value={s}>
                  {STATUS_LABEL[s]}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label>Ochiq?</label>
            <button
              className={`btn ${isOpen ? 'green' : 'red'}`}
              onClick={() => setIsOpen((v) => !v)}
              style={{ width: '100%' }}
            >
              {isOpen ? '🟢 Ochiq' : '🔴 Yopiq'}
            </button>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 14, flexWrap: 'wrap' }}>
          <button className="btn" disabled={saving} onClick={save}>
            {saving ? 'Saqlanmoqda…' : 'Saqlash'}
          </button>
          <button className="btn ghost" onClick={assignOwner}>
            {r.ownerUserId ? 'Egasini almashtirish' : 'Egasini biriktirish'}
          </button>
          <span className="muted" style={{ alignSelf: 'center', fontSize: 13 }}>
            ⭐ {r.rating.toFixed(1)} · ega:{' '}
            {r.ownerUserId ? `${r.ownerUserId.slice(0, 8)}…` : 'yo‘q'}
          </span>
        </div>
      </div>

      {/* Joylashuv (xarita) */}
      <div className="card" style={{ marginBottom: 16 }}>
        <div
          className="row"
          style={{ justifyContent: 'space-between', alignItems: 'center' }}
        >
          <strong>Xaritadagi joylashuv</strong>
          <span className="muted" style={{ fontSize: 13 }}>
            {lat.toFixed(5)}, {lng.toFixed(5)}
          </span>
        </div>
        <p className="muted" style={{ fontSize: 13, margin: '6px 0 10px' }}>
          Xaritani bosib oshxona aniq joylashuvini belgilang — keyin
          “Saqlash”ni bosing. (Mijoz va haydovchi shu nuqtani ko‘radi.)
        </p>
        <LocationMap
          lat={lat}
          lng={lng}
          onPick={(la, ln) => {
            setLat(la);
            setLng(ln);
          }}
        />
      </div>

      {/* Menyu (ko'rinish) */}
      <div className="card">
        <div
          className="row"
          style={{ justifyContent: 'space-between', alignItems: 'center' }}
        >
          <strong>Menyu</strong>
          <span className="muted" style={{ fontSize: 13 }}>
            {menu?.categories.length ?? 0} bo‘lim · {itemCount} taom
          </span>
        </div>
        {!menu || menu.categories.length === 0 ? (
          <p className="muted" style={{ marginTop: 8 }}>
            Menyu bo‘sh. Taomlar oshxona egasi panelida qo‘shiladi.
          </p>
        ) : (
          <div style={{ marginTop: 10 }}>
            {menu.categories.map((c) => (
              <div key={c.id} style={{ marginBottom: 12 }}>
                <div style={{ fontWeight: 700, marginBottom: 4 }}>{c.name}</div>
                {c.items.map((it) => (
                  <div
                    key={it.id}
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      padding: '6px 0',
                      borderBottom: '1px solid var(--border)',
                      opacity: it.isAvailable ? 1 : 0.5,
                    }}
                  >
                    <span>
                      {it.name}
                      {!it.isAvailable && (
                        <span className="muted"> (mavjud emas)</span>
                      )}
                    </span>
                    <strong>{formatSom(it.price)}</strong>
                  </div>
                ))}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
