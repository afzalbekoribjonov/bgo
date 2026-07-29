'use client';

import { useCallback, useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { cancelOrder, formatDate, formatSom, getOrder, rateOrder } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import type { StoreOrder } from '@/lib/types';

const DELIVERY_STEPS: { statuses: StoreOrder['status'][]; label: string }[] = [
  { statuses: ['PENDING'], label: 'Qabul qilinmoqda' },
  { statuses: ['ACCEPTED', 'ARRIVED'], label: "Haydovchi yo'lda" },
  { statuses: ['PICKED_UP'], label: 'Olindi' },
  { statuses: ['IN_TRANSIT'], label: "Sizga yo'lda" },
  { statuses: ['DELIVERED'], label: 'Yetkazildi' },
];

const PICKUP_STEPS: { statuses: StoreOrder['status'][]; label: string }[] = [
  { statuses: ['PENDING'], label: 'Tayyorlanmoqda' },
  { statuses: ['READY_FOR_PICKUP'], label: 'Tayyor' },
  { statuses: ['COMPLETED'], label: 'Olib ketildi' },
];

const CANCELLABLE: StoreOrder['status'][] = ['PENDING', 'ACCEPTED', 'ARRIVED', 'READY_FOR_PICKUP'];

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const toast = useToast();
  const dialog = useDialog();
  const [order, setOrder] = useState<StoreOrder | null>(null);
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState(false);
  const [rating, setRating] = useState(0);

  const load = useCallback(async () => {
    try {
      setOrder(await getOrder(id));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    load();
    const t = setInterval(load, 8000);
    return () => clearInterval(t);
  }, [load]);

  async function cancel() {
    const ok = await dialog.confirm('Buyurtmani bekor qilasizmi?', { danger: true, confirmLabel: 'Bekor qilish' });
    if (!ok) return;
    setCancelling(true);
    try {
      const updated = await cancelOrder(id);
      setOrder(updated);
      toast('Buyurtma bekor qilindi', 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setCancelling(false);
    }
  }

  async function submitRating(value: number) {
    setRating(value);
    try {
      const updated = await rateOrder(id, value);
      setOrder(updated);
      toast('Rahmat, bahoyingiz uchun!', 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  if (loading) {
    return (
      <>
        <div className="topbar">
          <button className="topbar-back" onClick={() => router.back()}>←</button>
          <span className="topbar-title">Yuklanmoqda...</span>
        </div>
      </>
    );
  }

  if (!order) {
    return (
      <div className="empty">
        <div className="empty-icon">😕</div>
        <div className="empty-title">Buyurtma topilmadi</div>
      </div>
    );
  }

  const steps = order.deliveryMethod === 'DELIVERY' ? DELIVERY_STEPS : PICKUP_STEPS;
  const isCancelled = order.status === 'CANCELLED';
  const currentIndex = isCancelled
    ? -1
    : steps.findIndex((s) => s.statuses.includes(order.status));
  const isDone = order.status === 'DELIVERED' || order.status === 'COMPLETED';

  return (
    <>
      <div className="topbar">
        <button className="topbar-back" onClick={() => router.back()}>←</button>
        <span className="topbar-title">Buyurtma #{order.publicNo}</span>
      </div>
      <div className="content">
        {isCancelled ? (
          <div className="err-block">Bu buyurtma bekor qilingan</div>
        ) : (
          <div className="steps-bar">
            {steps.map((s, i) => (
              <div key={s.label} className={`step ${i <= currentIndex ? 'done' : ''}`}>
                <div className="step-dot">{i <= currentIndex ? '✓' : i + 1}</div>
                <div className="step-label">{s.label}</div>
              </div>
            ))}
          </div>
        )}

        {order.deliveryMethod === 'DELIVERY' && order.driverName && !isDone && !isCancelled && (
          <div className="card card-p" style={{ marginBottom: 16 }}>
            <div className="row-sb">
              <div>
                <div style={{ fontWeight: 700, fontSize: 14 }}>{order.driverName}</div>
                <div className="text-sm muted">{order.driverCar} {order.driverPlate ? `· ${order.driverPlate}` : ''}</div>
              </div>
              {order.driverPhone && (
                <a className="btn btn-sm" href={`tel:${order.driverPhone}`}>📞 Qo'ng'iroq</a>
              )}
            </div>
          </div>
        )}

        {order.deliveryMethod === 'PICKUP' && order.pickupLocationName && (
          <div className="card card-p" style={{ marginBottom: 16 }}>
            <div className="text-sm text-3" style={{ marginBottom: 2 }}>Olib ketish joyi</div>
            <div style={{ fontWeight: 700 }}>{order.pickupLocationName}</div>
          </div>
        )}

        <div className="section-title">Mahsulotlar</div>
        <div className="card card-p" style={{ marginBottom: 16 }}>
          {order.items.map((i) => (
            <div key={`${i.productId}__${i.size ?? ''}`} className="summary-row">
              <span>
                {i.nameSnapshot}
                {i.size && <span className="size-tag">{i.size}</span>} ×{i.qty}
              </span>
              <span>{formatSom(i.lineTotal)}</span>
            </div>
          ))}
          <div className="summary-row">
            <span>Mahsulotlar</span>
            <span>{formatSom(order.itemsTotal)}</span>
          </div>
          {order.deliveryFee > 0 && (
            <div className="summary-row">
              <span>Yetkazish</span>
              <span>{formatSom(order.deliveryFee)}</span>
            </div>
          )}
          <div className="summary-row total">
            <span>Jami</span>
            <span>{formatSom(order.total)}</span>
          </div>
        </div>

        <div className="text-xs muted" style={{ marginBottom: 16 }}>
          Buyurtma vaqti: {formatDate(order.createdAt)}
        </div>

        {isDone && !order.rating && (
          <div className="card card-p" style={{ marginBottom: 16, textAlign: 'center' }}>
            <div style={{ fontWeight: 700, marginBottom: 10 }}>Buyurtmani baholang</div>
            <div style={{ fontSize: 26, letterSpacing: 4 }}>
              {[1, 2, 3, 4, 5].map((n) => (
                <span key={n} style={{ cursor: 'pointer', opacity: n <= rating ? 1 : 0.3 }} onClick={() => submitRating(n)}>
                  ⭐
                </span>
              ))}
            </div>
          </div>
        )}

        {CANCELLABLE.includes(order.status) && (
          <button className="btn red btn-block" disabled={cancelling} onClick={cancel}>
            {cancelling ? 'Bekor qilinmoqda...' : 'Buyurtmani bekor qilish'}
          </button>
        )}
      </div>
    </>
  );
}
