'use client';

import Link from 'next/link';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { createRestaurant, getManageRestaurants } from '@/lib/api';
import { useToast } from '@/components/toast';
import type { AdminRestaurant } from '@/lib/types';

const STATUS_BADGE: Record<AdminRestaurant['status'], { label: string; color: string }> = {
  ACTIVE: { label: 'Faol', color: 'var(--green)' },
  PENDING: { label: 'Kutilmoqda', color: 'var(--amber)' },
  BLOCKED: { label: 'Bloklangan', color: 'var(--red)' },
};

/** Bir sahifada ko'rsatiladigan oshxonalar soni — hamkorlar ko'paysa
 * sahifa minglab qatorni birdan render qilib og'irlashib ketmasin. */
const PAGE_SIZE = 40;

export default function RestaurantsPage() {
  const toast = useToast();
  const [restaurants, setRestaurants] = useState<AdminRestaurant[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [query, setQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | AdminRestaurant['status']>('all');
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);
  const [showCreate, setShowCreate] = useState(false);

  // Create form
  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [commission, setCommission] = useState('12');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setRestaurants(await getManageRestaurants());
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  async function add() {
    if (!name.trim() || !address.trim() || !phone.trim()) {
      toast("Nom, manzil va telefon to'ldirilishi shart", 'error');
      return;
    }
    setBusy(true);
    try {
      await createRestaurant({
        name: name.trim(),
        address: address.trim(),
        phone: phone.trim(),
        commissionPercent: parseInt(commission, 10) || 0,
      });
      setName(''); setAddress(''); setPhone(''); setCommission('12');
      setShowCreate(false);
      toast("Oshxona qo'shildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
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

  // Qidiruv/filtr o'zgarsa ko'rinadigan sahifa boshidan boshlansin.
  useEffect(() => setVisibleCount(PAGE_SIZE), [query, statusFilter]);

  const visible = filtered.slice(0, visibleCount);

  const stats = useMemo(() => ({
    total: restaurants.length,
    active: restaurants.filter((r) => r.status === 'ACTIVE').length,
    open: restaurants.filter((r) => r.isOpen).length,
  }), [restaurants]);

  return (
    <div className="container">
      {/* Header */}
      <div className="page-header">
        <div>
          <h1 className="page-title">Oshxonalar (hamkorlar)</h1>
          <p className="page-subtitle">{restaurants.length} ta hamkor oshxona</p>
        </div>
        <button className="btn" onClick={() => setShowCreate((v) => !v)}>
          {showCreate ? '✕ Yopish' : '+ Yangi oshxona'}
        </button>
      </div>

      {/* Stats */}
      <div className="stats">
        <div className="stat-card">
          <div className="stat-label">🏪 Jami</div>
          <div className="stat-value">{stats.total}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">✅ Faol</div>
          <div className="stat-value text-green">{stats.active}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">🟢 Hozir ochiq</div>
          <div className="stat-value text-blue">{stats.open}</div>
        </div>
      </div>

      {/* Create form */}
      {showCreate && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">Yangi oshxona qo'shish</span>
          </div>
          <div className="card-body">
            <div className="form-grid form-grid-auto" style={{ marginBottom: 14 }}>
              <div>
                <label>Nomi *</label>
                <input
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Milliy Taomlar"
                />
              </div>
              <div>
                <label>Manzil *</label>
                <input
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Beshariq, Navoiy ko'chasi 5"
                />
              </div>
              <div>
                <label>Telefon *</label>
                <input
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+99890..."
                />
              </div>
              <div>
                <label>Komissiya %</label>
                <input
                  value={commission}
                  inputMode="numeric"
                  onChange={(e) => setCommission(e.target.value.replace(/[^0-9]/g, ''))}
                />
              </div>
            </div>
            <button className="btn" disabled={busy} onClick={add}>
              {busy ? "Qo'shilyapti…" : "Qo'shish"}
            </button>
          </div>
        </div>
      )}

      {/* Filters */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap', alignItems: 'flex-end' }}>
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

      {/* List */}
      {loading ? (
        <div>
          {[...Array(5)].map((_, i) => (
            <div key={i} className="card" style={{ marginBottom: 8, padding: '16px 20px' }}>
              <div className="sk sk-line" style={{ width: '40%', marginBottom: 8, height: 16 }} />
              <div className="sk sk-line sk-line-md" style={{ height: 13 }} />
            </div>
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">🏪</div>
            <div className="empty-title">Oshxona topilmadi</div>
            <div className="empty-desc">Qidiruvni yoki filtrlni o'zgartiring</div>
          </div>
        </div>
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {visible.map((r) => {
            const st = STATUS_BADGE[r.status];
            return (
              <Link
                key={r.id}
                href={`/restaurants/${r.id}`}
                className="list-item card-link"
              >
                {/* Open indicator */}
                <div
                  style={{
                    width: 10,
                    height: 10,
                    borderRadius: '50%',
                    background: r.isOpen ? 'var(--green)' : '#94a3b8',
                    flexShrink: 0,
                    boxShadow: r.isOpen ? '0 0 6px var(--green)' : 'none',
                  }}
                  title={r.isOpen ? 'Ochiq' : 'Yopiq'}
                />

                {/* Info */}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--text)', marginBottom: 2 }}>
                    {r.name}
                  </div>
                  <div
                    style={{
                      fontSize: 12.5,
                      color: 'var(--text-muted)',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    📍 {r.address} · 📞 {r.phone}
                  </div>
                </div>

                {/* Rating */}
                <div style={{ fontSize: 13, color: 'var(--text-3)', flexShrink: 0 }}>
                  ⭐ {r.rating.toFixed(1)}
                </div>

                {/* Commission */}
                <div
                  style={{
                    fontSize: 12.5,
                    color: 'var(--text-muted)',
                    flexShrink: 0,
                    background: 'var(--surface-2)',
                    padding: '2px 8px',
                    borderRadius: 6,
                    border: '1px solid var(--border)',
                  }}
                >
                  {r.commissionPercent}%
                </div>

                {/* Status badge */}
                <span
                  className="badge"
                  style={{ background: st.color, flexShrink: 0, fontSize: 12 }}
                >
                  {st.label}
                </span>

                <span style={{ color: 'var(--text-muted)' }}>›</span>
              </Link>
            );
          })}
        </div>
      )}

      {filtered.length > visibleCount && (
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <button className="btn ghost" onClick={() => setVisibleCount((v) => v + PAGE_SIZE)}>
            Yana ko&apos;rsatish ({filtered.length - visibleCount} ta qoldi)
          </button>
        </div>
      )}
    </div>
  );
}
