'use client';

import { useCallback, useEffect, useState } from 'react';
import { formatDate, formatSom, getOrders } from '@/lib/api';
import { ORDER_STATUSES, statusColor, statusLabel } from '@/lib/status';
import type { AdminOrder } from '@/lib/types';

export default function OrdersPage() {
  const [orders, setOrders] = useState<AdminOrder[]>([]);
  const [status, setStatus] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setOrders(await getOrders(status || undefined));
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, [status]);

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
