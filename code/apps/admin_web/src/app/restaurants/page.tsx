'use client';

import Link from 'next/link';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { createRestaurant, getManageRestaurants } from '@/lib/api';
import type { AdminRestaurant } from '@/lib/types';

const STATUS: Record<
  AdminRestaurant['status'],
  { label: string; color: string }
> = {
  ACTIVE: { label: 'Faol', color: 'var(--green)' },
  PENDING: { label: 'Kutilmoqda', color: 'var(--orange)' },
  BLOCKED: { label: 'Bloklangan', color: 'var(--red)' },
};

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<AdminRestaurant[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);

  const [query, setQuery] = useState('');
  const [statusFilter, setStatusFilter] =
    useState<'all' | AdminRestaurant['status']>('all');
  const [showCreate, setShowCreate] = useState(false);

  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [commission, setCommission] = useState('12');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setRestaurants(await getManageRestaurants());
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function add() {
    if (!name.trim() || !address.trim() || !phone.trim()) return;
    setBusy(true);
    try {
      await createRestaurant({
        name: name.trim(),
        address: address.trim(),
        phone: phone.trim(),
        commissionPercent: parseInt(commission, 10) || 0,
      });
      setName('');
      setAddress('');
      setPhone('');
      setCommission('12');
      setShowCreate(false);
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return restaurants.filter(
      (r) =>
        (statusFilter === 'all' || r.status === statusFilter) &&
        (q === '' ||
          r.name.toLowerCase().includes(q) ||
          r.address.toLowerCase().includes(q) ||
          r.phone.includes(q)),
    );
  }, [restaurants, query, statusFilter]);

  const stats = useMemo(() => {
    const active = restaurants.filter((r) => r.status === 'ACTIVE').length;
    const open = restaurants.filter((r) => r.isOpen).length;
    return { total: restaurants.length, active, open };
  }, [restaurants]);

  return (
    <div className="container">
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 8,
        }}
      >
        <h1 className="h1" style={{ marginBottom: 0 }}>
          Oshxonalar (hamkorlar)
        </h1>
        <button className="btn" onClick={() => setShowCreate((v) => !v)}>
          {showCreate ? '✕ Yopish' : '+ Yangi oshxona'}
        </button>
      </div>

      {error && (
        <p className="error" style={{ marginTop: 12 }}>
          {error}
        </p>
      )}

      <div className="stats" style={{ marginTop: 16 }}>
        <div className="stat">
          <div className="muted">Jami</div>
          <strong style={{ fontSize: 24 }}>{stats.total}</strong>
        </div>
        <div className="stat">
          <div className="muted">Faol</div>
          <strong style={{ fontSize: 24, color: 'var(--green)' }}>
            {stats.active}
          </strong>
        </div>
        <div className="stat">
          <div className="muted">Hozir ochiq</div>
          <strong style={{ fontSize: 24, color: 'var(--blue)' }}>
            {stats.open}
          </strong>
        </div>
      </div>

      {showCreate && (
        <div className="card" style={{ marginBottom: 16 }}>
          <strong>Yangi oshxona qo‘shish</strong>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: '1.4fr 1.6fr 1fr 0.7fr auto',
              gap: 8,
              marginTop: 10,
              alignItems: 'end',
            }}
          >
            <div>
              <label>Nomi</label>
              <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Milliy Taomlar" />
            </div>
            <div>
              <label>Manzil</label>
              <input value={address} onChange={(e) => setAddress(e.target.value)} placeholder="Beshariq, ..." />
            </div>
            <div>
              <label>Telefon</label>
              <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+99890..." />
            </div>
            <div>
              <label>Komissiya %</label>
              <input
                value={commission}
                inputMode="numeric"
                onChange={(e) => setCommission(e.target.value.replace(/[^0-9]/g, ''))}
              />
            </div>
            <button className="btn" disabled={busy} onClick={add}>
              Qo&apos;shish
            </button>
          </div>
        </div>
      )}

      <div
        style={{
          display: 'flex',
          gap: 8,
          flexWrap: 'wrap',
          alignItems: 'end',
          marginBottom: 12,
        }}
      >
        <div style={{ flex: 1, minWidth: 220 }}>
          <label>Qidiruv</label>
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Nom, manzil yoki telefon…"
          />
        </div>
        <div>
          <label>Holat</label>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as typeof statusFilter)}
          >
            <option value="all">Barchasi</option>
            <option value="ACTIVE">Faol</option>
            <option value="PENDING">Kutilmoqda</option>
            <option value="BLOCKED">Bloklangan</option>
          </select>
        </div>
      </div>

      {loading && <p className="muted">Yuklanmoqda…</p>}
      {!loading && filtered.length === 0 && !error && (
        <p className="empty">Oshxona topilmadi</p>
      )}

      {/* Oddiy ro'yxat — bosilsa detal sahifa ochiladi */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {filtered.map((r) => {
          const st = STATUS[r.status];
          return (
            <Link
              key={r.id}
              href={`/restaurants/${r.id}`}
              className="card"
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                textDecoration: 'none',
                color: 'inherit',
                cursor: 'pointer',
              }}
            >
              <div style={{ flex: 1, minWidth: 0 }}>
                <strong style={{ fontSize: 16 }}>{r.name}</strong>
                <div
                  className="muted"
                  style={{
                    fontSize: 13,
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                  }}
                >
                  📍 {r.address} · 📞 {r.phone}
                </div>
              </div>
              <span className="muted" style={{ fontSize: 13 }}>
                ⭐ {r.rating.toFixed(1)}
              </span>
              <span className="muted" style={{ fontSize: 13 }}>
                {r.commissionPercent}%
              </span>
              <span style={{ fontSize: 16 }} title={r.isOpen ? 'Ochiq' : 'Yopiq'}>
                {r.isOpen ? '🟢' : '🔴'}
              </span>
              <span
                className="badge"
                style={{ background: st.color, whiteSpace: 'nowrap' }}
              >
                {st.label}
              </span>
              <span style={{ color: 'var(--muted)' }}>›</span>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
