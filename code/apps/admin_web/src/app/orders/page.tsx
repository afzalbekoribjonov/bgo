'use client';

import { useCallback, useEffect, useState } from 'react';
import { formatDate, formatSom, getOrders } from '@/lib/api';
import { ORDER_STATUSES, statusColor, statusLabel } from '@/lib/status';
import type { AdminOrder, OrdersQuery } from '@/lib/types';

export default function OrdersPage() {
  const [orders, setOrders] = useState<AdminOrder[]>([]);
  const [status, setStatus] = useState<string>('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [q, setQ] = useState('');
  const [sort, setSort] = useState<'createdAt' | 'total'>('createdAt');
  const [order, setOrder] = useState<'asc' | 'desc'>('desc');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const query: OrdersQuery = {
        status: status || undefined,
        from: from || undefined,
        to: to || undefined,
        q: q.trim() || undefined,
        sort,
        order,
      };
      setOrders(await getOrders(query));
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, [status, from, to, q, sort, order]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div className="container">
      <h1 className="h1">Buyurtmalar</h1>

      <div className="filters">
        <button
          className={`chip ${status === '' ? 'active' : ''}`}
          onClick={() => setStatus('')}
        >
          Hammasi
        </button>
        {ORDER_STATUSES.map((s) => (
          <button
            key={s}
            className={`chip ${status === s ? 'active' : ''}`}
            onClick={() => setStatus(s)}
          >
            {statusLabel(s)}
          </button>
        ))}
      </div>

      <div
        className="card"
        style={{ display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'end', marginBottom: 12 }}
      >
        <div>
          <label>Qidiruv (№ / manzil)</label>
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="#12 yoki ko'cha" />
        </div>
        <div>
          <label>Dan</label>
          <input type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
        </div>
        <div>
          <label>Gacha</label>
          <input type="date" value={to} onChange={(e) => setTo(e.target.value)} />
        </div>
        <div>
          <label>Saralash</label>
          <select value={sort} onChange={(e) => setSort(e.target.value as 'createdAt' | 'total')}>
            <option value="createdAt">Sana</option>
            <option value="total">Summa</option>
          </select>
        </div>
        <div>
          <label>Tartib</label>
          <select value={order} onChange={(e) => setOrder(e.target.value as 'asc' | 'desc')}>
            <option value="desc">Kamayish</option>
            <option value="asc">O&apos;sish</option>
          </select>
        </div>
        {(from || to || q || status) && (
          <button
            className="btn ghost"
            onClick={() => {
              setFrom('');
              setTo('');
              setQ('');
              setStatus('');
            }}
          >
            Tozalash
          </button>
        )}
      </div>

      {error && <p className="error">{error}</p>}
      {loading && <p className="muted">Yuklanmoqda…</p>}

      {!loading && !error && orders.length === 0 && (
        <p className="empty">Buyurtma topilmadi</p>
      )}

      {!loading && orders.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>№</th>
              <th>Tur</th>
              <th>Holat</th>
              <th>Summa</th>
              <th>Manzil</th>
              <th>Sana</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((o) => (
              <tr key={o.id}>
                <td>#{o.publicNo}</td>
                <td>{o.type}</td>
                <td>
                  <span className="badge" style={{ background: statusColor(o.status) }}>
                    {statusLabel(o.status)}
                  </span>
                </td>
                <td>{formatSom(o.total)}</td>
                <td>{o.address?.text ?? ''}</td>
                <td className="muted">{formatDate(o.createdAt)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
