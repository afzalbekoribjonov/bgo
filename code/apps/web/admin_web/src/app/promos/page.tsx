'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { createPromo, deletePromo, formatSom, getPromos, togglePromo } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import type { PromoCode } from '@/lib/types';

const TYPE_LABEL: Record<PromoCode['type'], string> = {
  PERCENT: 'Foiz',
  FIXED: 'Sobit summa',
};

export default function PromosPage() {
  const toast = useToast();
  const dialog = useDialog();
  const [promos, setPromos] = useState<PromoCode[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [filterActive, setFilterActive] = useState<'all' | 'active' | 'inactive'>('all');

  const [code, setCode] = useState('');
  const [type, setType] = useState<PromoCode['type']>('PERCENT');
  const [value, setValue] = useState('');
  const [minOrder, setMinOrder] = useState('');
  const [formErr, setFormErr] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setPromos(await getPromos());
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  async function add() {
    setFormErr('');
    if (!code.trim()) { setFormErr('Promokod matn kiriting'); return; }
    if (!value || parseInt(value, 10) <= 0) { setFormErr('Chegirma qiymatini kiriting'); return; }
    setBusy(true);
    try {
      await createPromo({
        code: code.trim().toUpperCase(),
        type,
        value: parseInt(value, 10) || 0,
        minOrder: parseInt(minOrder, 10) || 0,
      });
      setCode(''); setValue(''); setMinOrder(''); setFormErr('');
      setShowCreate(false);
      toast('Promokod yaratildi', 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(false);
    }
  }

  async function toggle(p: PromoCode) {
    try {
      await togglePromo(p.id, !p.active);
      toast(p.active ? "O'chirildi" : 'Yoqildi', 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  async function remove(p: PromoCode) {
    const ok = await dialog.confirm(
      `"${p.code}" promokodini o'chirasizmi? Bu amalni qaytarib bo'lmaydi.`,
      { title: "Promokodni o'chirish", danger: true },
    );
    if (!ok) return;
    try {
      await deletePromo(p.id);
      toast("O'chirildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  const filtered = useMemo(() =>
    promos.filter((p) =>
      filterActive === 'all' ? true : filterActive === 'active' ? p.active : !p.active,
    ),
  [promos, filterActive]);

  const stats = useMemo(() => ({
    total: promos.length,
    active: promos.filter((p) => p.active).length,
    uses: promos.reduce((s, p) => s + p.usedCount, 0),
  }), [promos]);

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Promokodlar</h1>
          <p className="page-subtitle">{promos.length} ta promokod</p>
        </div>
        <button className="btn" onClick={() => setShowCreate((v) => !v)}>
          {showCreate ? '✕ Yopish' : '+ Yangi promokod'}
        </button>
      </div>

      <div className="stats">
        <div className="stat-card">
          <div className="stat-label">🎫 Jami</div>
          <div className="stat-value">{stats.total}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">✅ Faol</div>
          <div className="stat-value text-green">{stats.active}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">📊 Jami ishlatilgan</div>
          <div className="stat-value">{stats.uses}</div>
        </div>
      </div>

      {showCreate && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">Yangi promokod yaratish</span>
          </div>
          <div className="card-body">
            <div className="form-grid form-grid-auto" style={{ marginBottom: 14 }}>
              <div>
                <label>Promokod *</label>
                <input
                  value={code}
                  onChange={(e) => setCode(e.target.value.toUpperCase().replace(/\s/g, ''))}
                  placeholder="SUMMER20"
                  style={{ fontFamily: 'monospace', fontSize: 15, letterSpacing: '1px' }}
                />
              </div>
              <div>
                <label>Tur</label>
                <select value={type} onChange={(e) => setType(e.target.value as PromoCode['type'])}>
                  <option value="PERCENT">Foiz (%)</option>
                  <option value="FIXED">Sobit summa (so'm)</option>
                </select>
              </div>
              <div>
                <label>Qiymat *</label>
                <input
                  value={value}
                  inputMode="numeric"
                  placeholder={type === 'PERCENT' ? '10' : '5000'}
                  onChange={(e) => setValue(e.target.value.replace(/\D/g, ''))}
                />
              </div>
              <div>
                <label>Minimal buyurtma (so'm)</label>
                <input
                  value={minOrder}
                  inputMode="numeric"
                  placeholder="0"
                  onChange={(e) => setMinOrder(e.target.value.replace(/\D/g, ''))}
                />
              </div>
            </div>
            {formErr && <div className="err-block" style={{ marginBottom: 12 }}>{formErr}</div>}
            <button className="btn" disabled={busy} onClick={add}>
              {busy ? 'Yaratilmoqda...' : 'Yaratish'}
            </button>
          </div>
        </div>
      )}

      <div className="filters" style={{ marginBottom: 16 }}>
        {(['all', 'active', 'inactive'] as const).map((f) => (
          <button
            key={f}
            className={`chip ${filterActive === f ? 'active' : ''}`}
            onClick={() => setFilterActive(f)}
          >
            {f === 'all' ? 'Barchasi' : f === 'active' ? 'Faol' : 'Nofaol'}
          </button>
        ))}
      </div>

      {loading ? (
        <div>
          {[...Array(4)].map((_, i) => (
            <div key={i} className="card" style={{ marginBottom: 8, padding: '16px 20px' }}>
              <div className="sk sk-line" style={{ width: '20%', marginBottom: 8, height: 16 }} />
              <div className="sk sk-line sk-line-md" style={{ height: 13 }} />
            </div>
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">🎫</div>
            <div className="empty-title">Promokod topilmadi</div>
            <div className="empty-desc">Yangi promokod yarating yoki filtrlni o'zgartiring</div>
          </div>
        </div>
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {filtered.map((p, i) => (
            <div
              key={p.id}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 14,
                padding: '14px 20px',
                borderBottom: i < filtered.length - 1 ? '1px solid var(--border)' : 'none',
                opacity: p.active ? 1 : 0.55,
              }}
            >
              <div
                style={{
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: 700,
                  letterSpacing: '1px',
                  color: 'var(--primary)',
                  background: 'color-mix(in srgb, var(--primary) 10%, transparent)',
                  padding: '4px 12px',
                  borderRadius: 6,
                  flexShrink: 0,
                  minWidth: 100,
                  textAlign: 'center',
                }}
              >
                {p.code}
              </div>

              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', marginBottom: 3 }}>
                  <span style={{ fontWeight: 700, fontSize: 14, color: 'var(--text)' }}>
                    {p.type === 'PERCENT' ? `-${p.value}%` : `-${formatSom(p.value)}`}
                  </span>
                  <span style={{ fontSize: 12, color: 'var(--text-muted)', background: 'var(--surface-2)', padding: '2px 7px', borderRadius: 5, border: '1px solid var(--border)' }}>
                    {TYPE_LABEL[p.type]}
                  </span>
                </div>
                <div style={{ fontSize: 12.5, color: 'var(--text-muted)', display: 'flex', gap: 10 }}>
                  {p.minOrder > 0 && <span>min: {formatSom(p.minOrder)}</span>}
                  <span>{p.usedCount} marta ishlatildi</span>
                </div>
              </div>

              <span
                className="badge"
                style={{
                  background: p.active ? 'var(--green)' : '#64748b',
                  fontSize: 11.5,
                  flexShrink: 0,
                }}
              >
                {p.active ? 'Faol' : 'Nofaol'}
              </span>

              <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
                <button
                  className={`btn btn-sm ${p.active ? 'ghost' : 'green'}`}
                  onClick={() => toggle(p)}
                  title={p.active ? "O'chirish" : 'Yoqish'}
                >
                  {p.active ? '⏸' : '▶'}
                </button>
                <button className="btn btn-sm red" onClick={() => remove(p)} title="O'chirish">
                  🗑
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
