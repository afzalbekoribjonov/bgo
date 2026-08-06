'use client';

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthState } from '@/lib/auth-context';
import { getMyOrders } from '@/lib/api';
import type { StoreOrder } from '@/lib/types';

const POLL_MS = 18000;

/**
 * PICKUP buyurtma "Tayyor" (READY_FOR_PICKUP) holatiga o'tganda — ilova
 * darajasida yopiladigan banner. Yopilgan buyurtma shu sessiyada qayta
 * ko'rsatilmaydi (lekin YANGI tayyor buyurtma bo'lsa ko'rinadi).
 */
export default function ReadyPickupBanner() {
  const { authed } = useAuthState();
  const router = useRouter();
  const [order, setOrder] = useState<StoreOrder | null>(null);
  const [dismissed, setDismissed] = useState<Set<string>>(new Set());

  const check = useCallback(async () => {
    try {
      const orders = await getMyOrders();
      const ready = orders
        .filter((o) => o.deliveryMethod === 'PICKUP' && o.status === 'READY_FOR_PICKUP')
        .filter((o) => !dismissed.has(o.id))
        .sort((a, b) => (b.readyAt ?? b.updatedAt).localeCompare(a.readyAt ?? a.updatedAt));
      setOrder(ready[0] ?? null);
    } catch {
      // best-effort — keyingi pollda qayta urinadi
    }
  }, [dismissed]);

  useEffect(() => {
    if (!authed) return;
    check();
    const t = setInterval(check, POLL_MS);
    return () => clearInterval(t);
  }, [authed, check]);

  if (!order) return null;

  return (
    <div
      onClick={() => router.push(`/orders/${order.id}`)}
      style={{
        position: 'fixed',
        top: 0,
        left: '50%',
        transform: 'translateX(-50%)',
        width: '100%',
        maxWidth: 480,
        zIndex: 60,
        background: 'var(--green)',
        color: '#fff',
        padding: '12px 16px',
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        cursor: 'pointer',
        boxShadow: '0 4px 16px rgba(0,0,0,0.12)',
      }}
    >
      <span style={{ fontSize: 20 }}>✅</span>
      <span style={{ flex: 1, fontSize: 13.5, fontWeight: 700, lineHeight: 1.3 }}>
        Buyurtma #{order.publicNo} tayyor — olib ketishingiz mumkin!
      </span>
      <button
        onClick={(e) => {
          e.stopPropagation();
          setDismissed((prev) => new Set(prev).add(order.id));
          setOrder(null);
        }}
        style={{
          background: 'rgba(255,255,255,0.2)',
          border: 'none',
          borderRadius: '50%',
          width: 26,
          height: 26,
          color: '#fff',
          fontSize: 15,
          lineHeight: 1,
          cursor: 'pointer',
          flexShrink: 0,
        }}
        aria-label="Yopish"
      >
        ×
      </button>
    </div>
  );
}
