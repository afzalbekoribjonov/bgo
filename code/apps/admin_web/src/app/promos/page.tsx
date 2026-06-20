'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  createPromo,
  deletePromo,
  formatSom,
  getPromos,
  togglePromo,
} from '@/lib/api';
import type { PromoCode } from '@/lib/types';

export default function PromosPage() {
  const [promos, setPromos] = useState<PromoCode[]>([]);
  const [error, setError] = useState<string | null>(null);

  const [code, setCode] = useState('');
  const [type, setType] = useState<'PERCENT' | 'FIXED'>('PERCENT');
  const [value, setValue] = useState('');
  const [minOrder, setMinOrder] = useState('0');

  const load = useCallback(async () => {
    try {
      setPromos(await getPromos());
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function add() {
    if (!code.trim() || !value) return;
    try {
      await createPromo({
        code: code.trim(),
        type,
        value: parseInt(value, 10) || 0,
        minOrder: parseInt(minOrder, 10) || 0,
      });
      setCode('');
      setValue('');
      setMinOrder('0');
      await load();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  return (
    <div className="container">
      <h1 className="h1">Promokodlar</h1>
      {error && <p className="error">{error}</p>}

      <div className="card" style={{ maxWidth: 640 }}>
        <strong>Yangi promokod</strong>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '1fr 1fr 1fr 1fr auto',
            gap: 8,
            marginTop: 8,
            alignItems: 'end',
          }}
        >
          <div>
            <label>Kod</label>
            <input value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} placeholder="BESH20" />
          </div>
          <div>
            <label>Turi</label>
            <select value={type} onChange={(e) => setType(e.target.value as 'PERCENT' | 'FIXED')}>
              <option value="PERCENT">Foiz (%)</option>
              <option value="FIXED">Summa (so&apos;m)</option>
            </select>
          </div>
          <div>
            <label>Qiymat</label>
            <input value={value} inputMode="numeric" onChange={(e) => setValue(e.target.value.replace(/[^0-9]/g, ''))} />
          </div>
          <div>
            <label>Min. buyurtma</label>
            <input value={minOrder} inputMode="numeric" onChange={(e) => setMinOrder(e.target.value.replace(/[^0-9]/g, ''))} />
          </div>
          <button className="btn" onClick={add}>
            Qo&apos;shish
          </button>
        </div>
      </div>

      {promos.length === 0 && !error && <p className="muted">Promokod yo&apos;q</p>}
      {promos.map((p) => (
        <div className="card" key={p.id}>
          <div className="row" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
            <div>
              <strong>{p.code}</strong>{' '}
              <span className="muted">
                {p.type === 'PERCENT' ? `${p.value}%` : formatSom(p.value)}
                {p.minOrder > 0 ? ` · min ${formatSom(p.minOrder)}` : ''} · {p.usedCount} marta
              </span>
            </div>
            <div className="btn-group" style={{ display: 'flex', gap: 8 }}>
              <button
                className={`btn ${p.active ? 'green' : 'ghost'}`}
                onClick={async () => {
                  await togglePromo(p.id, !p.active);
                  await load();
                }}
              >
                {p.active ? 'Faol' : 'O‘chiq'}
              </button>
              <button
                className="btn red"
                onClick={async () => {
                  await deletePromo(p.id);
                  await load();
                }}
              >
                O&apos;chirish
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
