'use client';

import { useCallback, useEffect, useState } from 'react';
import { formatSom, getKitchenHistory } from '@/lib/api';
import type { Order } from '@/lib/types';

const DONE = ['DELIVERED', 'COMPLETED'];
const CANCELLED = ['CANCELLED', 'FAILED'];

function statusLabel(status: string): { label: string; color: string; bg: string } {
  if (DONE.includes(status))
    return { label: 'Yetkazildi', color: 'var(--green)', bg: 'rgba(31,157,85,0.1)' };
  return { label: 'Bekor qilindi', color: 'var(--red)', bg: 'rgba(224,49,49,0.09)' };
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleString('uz-UZ', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

type Filter = 'all' | 'done' | 'cancelled';

export default function HistoryPage({ params }: { params: { id: string } }) {
  const rid = params.id;
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<Filter>('all');
  const [search, setSearch] = useState('');

  const load = useCallback(async () => {
    try {
      setOrders(await getKitchenHistory(rid));
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, [rid]);

  useEffect(() => {
    load();
  }, [load]);

  const visible = orders.filter((o) => {
    if (filter === 'done' && !DONE.includes(o.status)) return false;
    if (filter === 'cancelled' && !CANCELLED.includes(o.status)) return false;
    if (search) {
      const q = search.toLowerCase();
      const hay = `#${o.publicNo} ${o.address.text}`.toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });

  return (
    <div className="container" style={{ paddingBottom: 32 }}>
      <div className="row" style={{ marginBottom: 16, marginTop: 4 }}>
        <h2 className="big">Buyurtmalar tarixi</h2>
        <span className="time-chip">{orders.length} ta jami</span>
      </div>

      {/* Filter bar */}
      <div
        style={{
          display: 'flex',
          gap: 8,
          marginBottom: 14,
          flexWrap: 'wrap',
        }}
      >
        {(['all', 'done', 'cancelled'] as Filter[]).map((f) => (
          <button
            key={f}
            className={`btn sm ${filter === f ? '' : 'ghost'}`}
            style={
              filter === f
                ? {}
                : { borderColor: 'var(--border)', color: 'var(--muted)' }
            }
            onClick={() => setFilter(f)}
          >
            {f === 'all' ? 'Hammasi' : f === 'done' ? '✓ Yetkazildi' : '✕ Bekor'}
          </button>
        ))}
        <input
          placeholder="Qidirish (raqam, manzil…)"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ flex: 1, minWidth: 160, marginTop: 0 }}
        />
      </div>

      {error && (
        <div
          style={{
            background: 'rgba(224,49,49,0.07)',
            border: '1px solid rgba(224,49,49,0.3)',
            borderRadius: 12,
            padding: '12px 14px',
            marginBottom: 12,
            color: 'var(--red)',
            fontWeight: 700,
            fontSize: 14,
          }}
        >
          ⚠ {error}
        </div>
      )}

      {loading && (
        <p className="muted" style={{ textAlign: 'center', padding: '48px 0' }}>
          Yuklanmoqda…
        </p>
      )}

      {!loading && visible.length === 0 && (
        <div className="empty">
          <div style={{ fontSize: 38, marginBottom: 8 }}>📋</div>
          <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 4 }}>
            {search || filter !== 'all' ? 'Mos buyurtma topilmadi' : 'Hali yakunlangan buyurtma yo\'q'}
          </div>
        </div>
      )}

      {visible.map((o) => {
        const s = statusLabel(o.status);
        return (
          <div className="card" key={o.id}>
            <div className="row" style={{ marginBottom: 6 }}>
              <div className="order-no">#{o.publicNo}</div>
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 6,
                  background: s.bg,
                  color: s.color,
                  borderRadius: 20,
                  padding: '4px 12px',
                  fontSize: 13,
                  fontWeight: 800,
                }}
              >
                {s.label}
              </div>
            </div>

            <div className="order-addr">
              <span>📍</span>
              <span>{o.address.text}</span>
            </div>

            <div className="items">
              {o.items.map((it, i) => (
                <div className="item-row" key={i}>
                  <span>
                    {it.nameSnapshot} × <b>{it.qty}</b>
                  </span>
                  <span className="muted">{formatSom(it.lineTotal)}</span>
                </div>
              ))}
            </div>

            <div className="row">
              <span className="time-chip">{formatDate(o.createdAt)}</span>
              <span className="order-total">{formatSom(o.itemsTotal)}</span>
            </div>
          </div>
        );
      })}
    </div>
  );
}
