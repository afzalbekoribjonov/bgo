'use client';

import { useCallback, useEffect, useState } from 'react';
import { formatSom, getKitchenOrders, orderAction } from '@/lib/api';
import type { Order, OrderStatus } from '@/lib/types';

const STATUS_META: Record<string, { label: string; color: string }> = {
  PENDING: { label: 'Yangi', color: 'var(--orange)' },
  ACCEPTED: { label: 'Qabul qilindi', color: 'var(--blue)' },
  PREPARING: { label: 'Tayyorlanmoqda', color: 'var(--blue)' },
  READY: { label: 'Tayyor', color: 'var(--green)' },
  CANCELLED: { label: 'Bekor qilindi', color: 'var(--red)' },
  COMPLETED: { label: 'Yakunlandi', color: 'var(--green)' },
  DELIVERED: { label: 'Yetkazildi', color: 'var(--green)' },
};

function statusMeta(status: OrderStatus) {
  return STATUS_META[status] ?? { label: status, color: 'var(--muted)' };
}

export default function OrdersPage({ params }: { params: { id: string } }) {
  const rid = params.id;
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setOrders(await getKitchenOrders(rid));
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    }
  }, [rid]);

  useEffect(() => {
    load();
    const timer = setInterval(load, 5000);
    return () => clearInterval(timer);
  }, [load]);

  async function act(
    id: string,
    action: 'accept' | 'preparing' | 'ready' | 'reject',
  ) {
    setBusy(id);
    try {
      await orderAction(id, action);
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="container">
      <div className="row" style={{ marginBottom: 16 }}>
        <h2 className="big">Buyurtmalar</h2>
        <span className="muted">Har 5 soniyada yangilanadi</span>
      </div>
      {error && <p className="error">{error}</p>}
      {orders.length === 0 && !error && (
        <p className="empty">Hozircha buyurtma yo'q</p>
      )}
      {orders.map((o) => {
        const meta = statusMeta(o.status);
        const isBusy = busy === o.id;
        return (
          <div className="card" key={o.id}>
            <div className="row">
              <div className="title">Buyurtma #{o.publicNo}</div>
              <span className="badge" style={{ background: meta.color }}>
                {meta.label}
              </span>
            </div>
            <div style={{ margin: '8px 0' }}>
              {o.items.map((it, i) => (
                <div className="row" key={i}>
                  <span>
                    {it.nameSnapshot} × {it.qty}
                  </span>
                  <span className="muted">{formatSom(it.lineTotal)}</span>
                </div>
              ))}
            </div>
            <div className="row">
              <span className="muted">📍 {o.address.text}</span>
              <span className="title">{formatSom(o.total)}</span>
            </div>
            <div className="btn-group" style={{ marginTop: 12 }}>
              {o.status === 'PENDING' && (
                <>
                  <button
                    className="btn green"
                    disabled={isBusy}
                    onClick={() => act(o.id, 'accept')}
                  >
                    Qabul qilish
                  </button>
                  <button
                    className="btn red"
                    disabled={isBusy}
                    onClick={() => act(o.id, 'reject')}
                  >
                    Rad etish
                  </button>
                </>
              )}
              {o.status === 'ACCEPTED' && (
                <button
                  className="btn orange"
                  disabled={isBusy}
                  onClick={() => act(o.id, 'preparing')}
                >
                  Tayyorlanmoqda
                </button>
              )}
              {o.status === 'PREPARING' && (
                <button
                  className="btn green"
                  disabled={isBusy}
                  onClick={() => act(o.id, 'ready')}
                >
                  Tayyor
                </button>
              )}
              {o.status === 'READY' && (
                <span className="muted">Kuryer kutilmoqda…</span>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
