'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  assignRestaurantOwner,
  createRestaurant,
  getManageRestaurants,
  updateRestaurant,
} from '@/lib/api';
import type { AdminRestaurant } from '@/lib/types';

const STATUS_LABEL: Record<AdminRestaurant['status'], string> = {
  ACTIVE: 'Faol',
  PENDING: 'Kutilmoqda',
  BLOCKED: 'Bloklangan',
};

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<AdminRestaurant[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);

  // Yangi oshxona formasi
  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [commission, setCommission] = useState('0');

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
      setCommission('0');
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(null);
    }
  }

  async function patch(id: string, body: Parameters<typeof updateRestaurant>[1]) {
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

  return (
    <div className="container">
      <h1 className="h1">Oshxonalar</h1>
      {error && <p className="error">{error}</p>}

      <div className="card" style={{ maxWidth: 720 }}>
        <strong>Yangi oshxona</strong>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '1.4fr 1.6fr 1fr 0.7fr auto',
            gap: 8,
            marginTop: 8,
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

      {loading && <p className="muted">Yuklanmoqda…</p>}
      {!loading && restaurants.length === 0 && !error && (
        <p className="empty">Oshxona topilmadi</p>
      )}

      {!loading && restaurants.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Nomi</th>
              <th>Telefon</th>
              <th>Komissiya</th>
              <th>Holat</th>
              <th>Ochiq?</th>
              <th>Egasi</th>
              <th>Amallar</th>
            </tr>
          </thead>
          <tbody>
            {restaurants.map((r) => (
              <tr key={r.id}>
                <td>
                  {r.name}
                  <div className="muted" style={{ fontSize: 12 }}>{r.address}</div>
                </td>
                <td className="muted">{r.phone}</td>
                <td>{r.commissionPercent}%</td>
                <td>
                  <select
                    value={r.status}
                    disabled={busy === r.id}
                    onChange={(e) =>
                      patch(r.id, { status: e.target.value as AdminRestaurant['status'] })
                    }
                  >
                    {(['ACTIVE', 'PENDING', 'BLOCKED'] as const).map((s) => (
                      <option key={s} value={s}>{STATUS_LABEL[s]}</option>
                    ))}
                  </select>
                </td>
                <td>
                  <button
                    className={`btn ${r.isOpen ? 'green' : 'red'}`}
                    disabled={busy === r.id}
                    onClick={() => patch(r.id, { isOpen: !r.isOpen })}
                  >
                    {r.isOpen ? 'Ochiq' : 'Yopiq'}
                  </button>
                </td>
                <td className="muted" style={{ fontSize: 12 }}>
                  {r.ownerUserId ? `${r.ownerUserId.slice(0, 8)}…` : '—'}
                </td>
                <td>
                  <button
                    className="btn ghost"
                    disabled={busy === r.id}
                    onClick={() => assignOwner(r)}
                  >
                    Egasini biriktirish
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
