'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  assignRestaurantOwner,
  createRestaurant,
  formatDate,
  getManageRestaurants,
  updateRestaurant,
} from '@/lib/api';
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
  const [busy, setBusy] = useState<string | null>(null);

  const [query, setQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | AdminRestaurant['status']>('all');
  const [showCreate, setShowCreate] = useState(false);

  // Yangi oshxona formasi
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
    setBusy('new');
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
      setBusy(null);
    }
  }

  async function patch(
    id: string,
    body: Parameters<typeof updateRestaurant>[1],
  ) {
    setBusy(id);
    try {
      await updateRestaurant(id, body);
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(null);
    }
  }

  async function assignOwner(r: AdminRestaurant) {
    const ownerUserId = window.prompt(
      `"${r.name}" egasining foydalanuvchi ID'si:`,
      r.ownerUserId ?? '',
    );
    if (!ownerUserId) return;
    setBusy(r.id);
    try {
      await assignRestaurantOwner(r.id, ownerUserId.trim());
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(null);
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
    const avgComm = restaurants.length
      ? Math.round(
          restaurants.reduce((s, r) => s + r.commissionPercent, 0) /
            restaurants.length,
        )
      : 0;
    return { total: restaurants.length, active, open, avgComm };
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

      {error && <p className="error" style={{ marginTop: 12 }}>{error}</p>}

      {/* Statistika */}
      <div className="stats" style={{ marginTop: 16 }}>
        <div className="stat">
          <div className="muted">Jami oshxona</div>
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
        <div className="stat">
          <div className="muted">O‘rtacha komissiya</div>
          <strong style={{ fontSize: 24 }}>{stats.avgComm}%</strong>
        </div>
      </div>

      {/* Yangi oshxona formasi */}
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
            <button className="btn" disabled={busy === 'new'} onClick={add}>
              Qo&apos;shish
            </button>
          </div>
        </div>
      )}

      {/* Qidiruv + filtr */}
      <div
        style={{
          display: 'flex',
          gap: 8,
          flexWrap: 'wrap',
          alignItems: 'end',
          marginBottom: 16,
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
            onChange={(e) =>
              setStatusFilter(e.target.value as typeof statusFilter)
            }
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

      {/* Oshxona kartalari */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))',
          gap: 16,
        }}
      >
        {filtered.map((r) => (
          <RestaurantCard
            key={r.id}
            r={r}
            busy={busy === r.id}
            onPatch={(b) => patch(r.id, b)}
            onAssign={() => assignOwner(r)}
          />
        ))}
      </div>
    </div>
  );
}

function RestaurantCard({
  r,
  busy,
  onPatch,
  onAssign,
}: {
  r: AdminRestaurant;
  busy: boolean;
  onPatch: (body: Parameters<typeof updateRestaurant>[1]) => void;
  onAssign: () => void;
}) {
  const st = STATUS[r.status];
  return (
    <div
      className="card"
      style={{ display: 'flex', flexDirection: 'column', gap: 10 }}
    >
      {/* Sarlavha */}
      <div
        style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}
      >
        <div style={{ minWidth: 0 }}>
          <strong style={{ fontSize: 17 }}>{r.name}</strong>
          <div className="muted" style={{ fontSize: 12 }}>
            {formatDate(r.createdAt)} dan beri
          </div>
        </div>
        <span
          className="badge"
          style={{ background: st.color, alignSelf: 'flex-start' }}
        >
          {st.label}
        </span>
      </div>

      {/* Ma'lumotlar */}
      <div style={{ display: 'grid', gap: 4, fontSize: 14 }}>
        <Row icon="📍" text={r.address} />
        <Row icon="📞" text={r.phone} />
        <Row icon="⭐" text={`${r.rating.toFixed(1)} reyting`} />
        <Row icon="💰" text={`Komissiya: ${r.commissionPercent}%`} />
        <Row
          icon="👤"
          text={
            r.ownerUserId
              ? `Ega: ${r.ownerUserId.slice(0, 8)}…`
              : 'Ega biriktirilmagan'
          }
          muted={!r.ownerUserId}
        />
      </div>

      {/* Amallar */}
      <div
        style={{
          display: 'flex',
          gap: 8,
          flexWrap: 'wrap',
          alignItems: 'center',
          borderTop: '1px solid var(--border)',
          paddingTop: 10,
          marginTop: 'auto',
        }}
      >
        <button
          className={`btn ${r.isOpen ? 'green' : 'red'}`}
          disabled={busy}
          onClick={() => onPatch({ isOpen: !r.isOpen })}
          title="Ochiq/Yopiq holatini almashtirish"
        >
          {r.isOpen ? '🟢 Ochiq' : '🔴 Yopiq'}
        </button>
        <select
          value={r.status}
          disabled={busy}
          onChange={(e) =>
            onPatch({ status: e.target.value as AdminRestaurant['status'] })
          }
        >
          {(['ACTIVE', 'PENDING', 'BLOCKED'] as const).map((s) => (
            <option key={s} value={s}>
              {STATUS[s].label}
            </option>
          ))}
        </select>
        <button className="btn ghost" disabled={busy} onClick={onAssign}>
          Egasini biriktirish
        </button>
      </div>
    </div>
  );
}

function Row({
  icon,
  text,
  muted,
}: {
  icon: string;
  text: string;
  muted?: boolean;
}) {
  return (
    <div
      style={{
        display: 'flex',
        gap: 6,
        color: muted ? 'var(--muted)' : 'var(--text)',
      }}
    >
      <span style={{ width: 18 }}>{icon}</span>
      <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
        {text}
      </span>
    </div>
  );
}
