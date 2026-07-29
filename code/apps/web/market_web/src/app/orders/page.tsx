'use client';

import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { formatDate, formatSom, getMyOrders } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useAuthState } from '@/lib/auth-context';
import type { StoreOrder, StoreOrderStatus } from '@/lib/types';

const STATUS_LABEL: Record<StoreOrderStatus, string> = {
  PENDING: 'Kutilmoqda',
  ACCEPTED: 'Qabul qilindi',
  ARRIVED: 'Haydovchi yo\'lda',
  PICKED_UP: 'Olindi',
  IN_TRANSIT: "Sizga yo'lda",
  DELIVERED: 'Yetkazildi',
  READY_FOR_PICKUP: 'Olib ketishga tayyor',
  COMPLETED: 'Yakunlandi',
  CANCELLED: 'Bekor qilindi',
};

const STATUS_COLOR: Record<StoreOrderStatus, string> = {
  PENDING: 'var(--amber)',
  ACCEPTED: 'var(--brand)',
  ARRIVED: 'var(--brand)',
  PICKED_UP: 'var(--brand)',
  IN_TRANSIT: 'var(--brand)',
  DELIVERED: 'var(--green)',
  READY_FOR_PICKUP: 'var(--amber)',
  COMPLETED: 'var(--green)',
  CANCELLED: 'var(--red)',
};

export default function OrdersPage() {
  const toast = useToast();
  const { ready, authed } = useAuthState();
  const [orders, setOrders] = useState<StoreOrder[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setOrders(await getMyOrders());
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    if (ready && authed) load();
  }, [ready, authed, load]);

  return (
    <>
      <div className="topbar">
        <span className="topbar-title">📦 Buyurtmalarim</span>
      </div>
      <div className="content">
        {!ready ? null : !authed ? (
          <div className="empty">
            <div className="empty-icon">🔒</div>
            <div className="empty-title">Buyurtmalaringizni ko'rish uchun ilovadan oching</div>
          </div>
        ) : loading ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[...Array(3)].map((_, i) => <div key={i} className="sk sk-line" style={{ height: 70 }} />)}
          </div>
        ) : orders.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">📦</div>
            <div className="empty-title">Hali buyurtma yo'q</div>
          </div>
        ) : (
          orders.map((o) => (
            <Link key={o.id} href={`/orders/${o.id}`} className="order-card" style={{ display: 'block' }}>
              <div className="row-sb" style={{ marginBottom: 6 }}>
                <span style={{ fontWeight: 800, fontSize: 14 }}>#{o.publicNo}</span>
                <span className="status-badge" style={{ background: 'var(--surface-2)', color: STATUS_COLOR[o.status] }}>
                  <span className="status-dot" style={{ background: STATUS_COLOR[o.status] }} />
                  {STATUS_LABEL[o.status]}
                </span>
              </div>
              <div className="text-sm text-3" style={{ marginBottom: 4 }}>
                {o.items
                  .map((i) => `${i.nameSnapshot}${i.size ? ` (${i.size})` : ''} ×${i.qty}`)
                  .join(', ')}
              </div>
              <div className="row-sb">
                <span className="text-xs muted">{formatDate(o.createdAt)}</span>
                <span style={{ fontWeight: 800, fontSize: 14 }}>{formatSom(o.total)}</span>
              </div>
            </Link>
          ))
        )}
      </div>
    </>
  );
}
