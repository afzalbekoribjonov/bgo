'use client';

import { useEffect, useState } from 'react';
import { getTariff, updateTariff } from '@/lib/api';
import type { Tariff } from '@/lib/types';

export default function TariffPage() {
  const [tariff, setTariff] = useState<Tariff | null>(null);
  const [fee, setFee] = useState('');
  const [pct, setPct] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    getTariff()
      .then((t) => {
        setTariff(t);
        setFee(String(t.deliveryFee));
        setPct(String(t.foodCommissionPercent));
      })
      .catch((e) => setError(e.message));
  }, []);

  async function save() {
    setLoading(true);
    setError(null);
    setSaved(false);
    try {
      const t = await updateTariff({
        deliveryFee: parseInt(fee, 10) || 0,
        foodCommissionPercent: parseInt(pct, 10) || 0,
      });
      setTariff(t);
      setSaved(true);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="container">
      <h1 className="h1">Tariflar</h1>
      {error && <p className="error">{error}</p>}
      {!tariff && !error && <p className="muted">Yuklanmoqda…</p>}
      {tariff && (
        <div className="card" style={{ maxWidth: 480 }}>
          <label>Yetkazib berish narxi (so&apos;m)</label>
          <input
            value={fee}
            inputMode="numeric"
            onChange={(e) => setFee(e.target.value.replace(/[^0-9]/g, ''))}
          />
          <label style={{ marginTop: 12 }}>Oshxona komissiyasi (%)</label>
          <input
            value={pct}
            inputMode="numeric"
            onChange={(e) => setPct(e.target.value.replace(/[^0-9]/g, ''))}
          />
          <p className="muted" style={{ marginTop: 8 }}>
            Komissiya — har ovqat buyurtmasidan bizning ulush (foyda).
          </p>
          {saved && <p style={{ color: 'var(--green, green)' }}>Saqlandi ✓</p>}
          <button
            className="btn"
            style={{ marginTop: 12 }}
            disabled={loading}
            onClick={save}
          >
            {loading ? '...' : 'Saqlash'}
          </button>
        </div>
      )}
    </div>
  );
}
