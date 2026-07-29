'use client';

import Link from 'next/link';
import { useParams, useRouter, useSearchParams } from 'next/navigation';
import { Suspense, useCallback, useEffect, useState } from 'react';
import { cancelOrder, formatDate, formatSom, getOrderDetail } from '@/lib/api';
import { statusColor, statusLabel } from '@/lib/status';
import { useToast } from '@/components/toast';
import type { OrderDetail, OrderStatusHistoryEntry } from '@/lib/types';

const VERTICAL_LABEL: Record<string, string> = {
  FOOD: '🍽️ Ovqat buyurtmasi',
  TAXI: '🚕 Taksi safari',
  PARCEL: '📦 Dostavka',
};

const ACTOR_LABEL: Record<string, string> = {
  customer: '👤 Mijoz',
  kitchen: '🍳 Oshxona',
  driver: '🚗 Haydovchi',
  admin: '🛡️ Admin',
  system: '⚙️ Tizim',
};

function PersonCard({
  icon,
  title,
  name,
  phone,
  extra,
}: {
  icon: string;
  title: string;
  name: string | null | undefined;
  phone: string | null | undefined;
  extra?: string | null;
}) {
  return (
    <div style={{ background: 'var(--surface-2)', border: '1px solid var(--border)', borderRadius: 10, padding: '14px 16px' }}>
      <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: 8 }}>
        {icon} {title}
      </div>
      <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--text)' }}>
        {name?.trim() || <span style={{ color: 'var(--text-muted)', fontWeight: 500 }}>Ism kiritilmagan</span>}
      </div>
      {phone && <div style={{ fontSize: 13, color: 'var(--text-3)', marginTop: 3 }}>📞 {phone}</div>}
      {extra && <div style={{ fontSize: 13, color: 'var(--text-3)', marginTop: 3 }}>{extra}</div>}
    </div>
  );
}

function Row({ label, value, strong, color }: { label: string; value: React.ReactNode; strong?: boolean; color?: string }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '9px 0', borderBottom: '1px solid var(--border)' }}>
      <span style={{ fontSize: 13.5, color: 'var(--text-3)' }}>{label}</span>
      <span style={{ fontSize: strong ? 16 : 13.5, fontWeight: strong ? 700 : 600, color: color ?? 'var(--text)' }}>{value}</span>
    </div>
  );
}

function Timeline({ history }: { history: OrderStatusHistoryEntry[] }) {
  if (history.length === 0) {
    return <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>Tarix mavjud emas</p>;
  }
  return (
    <div style={{ display: 'flex', flexDirection: 'column' }}>
      {history.map((h, i) => {
        const isLast = i === history.length - 1;
        const isCancelled = ['CANCELLED', 'FAILED'].includes(h.status);
        return (
          <div key={i} style={{ display: 'flex', gap: 12 }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: 20 }}>
              <div
                style={{
                  width: 12,
                  height: 12,
                  borderRadius: '50%',
                  background: statusColor(h.status),
                  flexShrink: 0,
                  marginTop: 3,
                }}
              />
              {!isLast && <div style={{ width: 2, flex: 1, background: 'var(--border)', minHeight: 24 }} />}
            </div>
            <div style={{ paddingBottom: 20, flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                <span
                  className="badge"
                  style={{ background: statusColor(h.status), fontSize: 11.5 }}
                >
                  {statusLabel(h.status)}
                </span>
                <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{formatDate(h.at)}</span>
              </div>
              {(h.by || h.driverName || h.reason) && (
                <div style={{ marginTop: 6, fontSize: 13, color: isCancelled ? 'var(--red)' : 'var(--text-3)' }}>
                  {h.by && <span>{ACTOR_LABEL[h.by] ?? h.by}</span>}
                  {h.driverName && (
                    <span>
                      {h.by ? ' · ' : ''}🚗 {h.driverName}
                    </span>
                  )}
                  {h.reason && <div style={{ marginTop: 2, fontStyle: 'italic' }}>&quot;{h.reason}&quot;</div>}
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

export default function OrderDetailPage() {
  return (
    <Suspense fallback={<div className="container"><div className="sk sk-title" style={{ width: '40%' }} /></div>}>
      <OrderDetailContent />
    </Suspense>
  );
}

function OrderDetailContent() {
  const params = useParams<{ id: string }>();
  const search = useSearchParams();
  const router = useRouter();
  const toast = useToast();
  const id = params.id;
  const type = (search.get('type') as 'FOOD' | 'TAXI' | 'PARCEL') ?? 'FOOD';

  const [o, setO] = useState<OrderDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setO(await getOrderDetail(id, type));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [id, type]);

  useEffect(() => { load(); }, [load]);

  async function handleCancel() {
    if (!confirm('Buyurtmani bekor qilasizmi?')) return;
    setCancelling(true);
    try {
      await cancelOrder(id);
      toast('Buyurtma bekor qilindi', 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setCancelling(false);
    }
  }

  if (loading) {
    return (
      <div className="container">
        <div className="sk sk-title" style={{ marginBottom: 20, width: '40%' }} />
        {[...Array(3)].map((_, i) => (
          <div key={i} className="card" style={{ marginBottom: 16 }}>
            <div className="card-body"><div className="sk sk-para" /></div>
          </div>
        ))}
      </div>
    );
  }

  if (!o) {
    return (
      <div className="container">
        <Link href="/orders" className="btn ghost" style={{ marginBottom: 16 }}>← Buyurtmalar</Link>
        <div className="card">
          <div className="empty">
            <div className="empty-icon">🔍</div>
            <div className="empty-title">Buyurtma topilmadi</div>
          </div>
        </div>
      </div>
    );
  }

  const active = !['DELIVERED', 'CANCELLED', 'FAILED', 'COMPLETED'].includes(o.status);
  const total = o.type === 'FOOD' ? o.total : o.type === 'TAXI' ? o.fare : o.fare;

  return (
    <div className="container">
      {/* Breadcrumb */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20 }}>
        <Link href="/orders" style={{ color: 'var(--text-muted)', textDecoration: 'none', fontSize: 13.5 }}>
          Buyurtmalar
        </Link>
        <span style={{ color: 'var(--text-muted)' }}>›</span>
        <span style={{ fontSize: 13.5, color: 'var(--text-2)', fontWeight: 600 }}>#{o.publicNo}</span>
      </div>

      {/* Header */}
      <div className="page-header">
        <div>
          <h1 className="page-title">{VERTICAL_LABEL[o.type]} #{o.publicNo}</h1>
          <div style={{ display: 'flex', gap: 10, marginTop: 6, alignItems: 'center', flexWrap: 'wrap' }}>
            <span className="badge" style={{ background: statusColor(o.status), fontSize: 12.5 }}>
              {statusLabel(o.status)}
            </span>
            <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>
              Yaratildi: {formatDate(o.createdAt)}
            </span>
            <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>·</span>
            <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>
              Yangilandi: {formatDate(o.updatedAt)}
            </span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {active && (
            <button className="btn red" disabled={cancelling} onClick={handleCancel}>
              {cancelling ? '…' : '✕ Majburiy bekor qilish'}
            </button>
          )}
          <button className="btn ghost" onClick={() => router.push('/orders')}>
            ↺ Yangilash
          </button>
        </div>
      </div>

      {/* Ishtirokchilar */}
      <div className="card" style={{ marginBottom: 16 }}>
        <div className="card-header">
          <span className="card-title">👥 Ishtirokchilar</span>
        </div>
        <div className="card-body">
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 12 }}>
            <PersonCard icon="👤" title="Mijoz" name={o.customer.name} phone={o.customer.phone} />
            {o.driver ? (
              <PersonCard
                icon="🚗"
                title="Haydovchi"
                name={o.driver.name}
                phone={o.driver.phone}
                extra={o.driver.car ? `${o.driver.car}${o.driver.plate ? ` · ${o.driver.plate}` : ''}` : null}
              />
            ) : (
              <div style={{ background: 'var(--surface-2)', border: '1px dashed var(--border)', borderRadius: 10, padding: '14px 16px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)', fontSize: 13 }}>
                Haydovchi biriktirilmagan
              </div>
            )}
            {o.type === 'FOOD' && o.restaurant && (
              <PersonCard icon="🍽️" title="Oshxona" name={o.restaurant.name} phone={null} extra={o.restaurant.address} />
            )}
            {o.type === 'PARCEL' && (
              <PersonCard icon="📬" title="Qabul qiluvchi" name={o.recipientName} phone={o.recipientPhone} />
            )}
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) minmax(0, 1fr)', gap: 16 }}>
        {/* Chap: narx/marshrut tafsilotlari */}
        <div>
          {o.type === 'FOOD' && (
            <>
              <div className="card" style={{ marginBottom: 16 }}>
                <div className="card-header"><span className="card-title">🧾 Taomlar</span></div>
                <div className="card-body">
                  {(o.items ?? []).map((it, i) => (
                    <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '7px 0', borderBottom: '1px solid var(--border)', fontSize: 13.5 }}>
                      <span>{it.nameSnapshot} × <b>{it.qty}</b></span>
                      <span style={{ color: 'var(--text-3)' }}>{formatSom(it.lineTotal)}</span>
                    </div>
                  ))}
                </div>
              </div>
              <div className="card" style={{ marginBottom: 16 }}>
                <div className="card-header"><span className="card-title">💰 Narx tafsiloti</span></div>
                <div className="card-body">
                  <Row label="Taomlar summasi (oshxonaga)" value={formatSom(o.itemsTotal ?? 0)} />
                  <Row label="Xizmat haqi (platforma)" value={formatSom(o.serviceFee ?? 0)} color="var(--amber)" />
                  <Row label="Yetkazish haqi (haydovchiga)" value={formatSom(o.deliveryFee ?? 0)} color="var(--green)" />
                  {(o.discount ?? 0) > 0 && <Row label={`Chegirma${o.promoCode ? ` (${o.promoCode})` : ''}`} value={`− ${formatSom(o.discount ?? 0)}`} color="var(--red)" />}
                  <Row label="Jami (mijoz to'lovi)" value={formatSom(o.total ?? 0)} strong />
                  <Row label="To'lov turi" value={o.paymentType} />
                </div>
              </div>
            </>
          )}

          {o.type === 'TAXI' && (
            <>
              <div className="card" style={{ marginBottom: 16 }}>
                <div className="card-header"><span className="card-title">🗺️ Marshrut</span></div>
                <div className="card-body">
                  <Row label="Qayerdan" value={o.pickup?.text ?? '—'} />
                  <Row label="Qayerga" value={o.metered ? 'Manzilsiz (soatbay)' : (o.destination?.text ?? '—')} />
                  <Row label="Masofa" value={`${(o.distanceKm ?? 0).toFixed(1)} km`} />
                  <Row label="Olib ketish masofasi" value={`${(o.pickupDistanceKm ?? 0).toFixed(1)} km`} />
                  <Row label="Kutish vaqti" value={`${o.waitMinutes ?? 0} daqiqa`} />
                </div>
              </div>
              <div className="card" style={{ marginBottom: 16 }}>
                <div className="card-header"><span className="card-title">💰 Narx tafsiloti</span></div>
                <div className="card-body">
                  <Row label="Olib ketish ustamasi" value={formatSom(o.pickupSurcharge ?? 0)} />
                  <Row label="Safar haqi (jami)" value={formatSom(o.fare ?? 0)} strong />
                  <Row label="Platforma komissiyasi" value={formatSom(o.commission ?? 0)} color="var(--amber)" />
                  <Row label="Haydovchi daromadi" value={formatSom(o.driverEarning ?? 0)} color="var(--green)" />
                  <Row label="To'lov turi" value={o.paymentType} />
                </div>
              </div>
            </>
          )}

          {o.type === 'PARCEL' && (
            <>
              <div className="card" style={{ marginBottom: 16 }}>
                <div className="card-header"><span className="card-title">🗺️ Marshrut</span></div>
                <div className="card-body">
                  <Row label="Qayerdan" value={o.pickup?.text ?? '—'} />
                  <Row label="Qayerga" value={o.destination?.text ?? '—'} />
                  <Row label="Masofa" value={`${(o.distanceKm ?? 0).toFixed(1)} km`} />
                  <Row label="O'lcham" value={o.size ?? '—'} />
                  {o.note && <Row label="Izoh" value={o.note} />}
                </div>
              </div>
              <div className="card" style={{ marginBottom: 16 }}>
                <div className="card-header"><span className="card-title">💰 Narx tafsiloti</span></div>
                <div className="card-body">
                  <Row label="Dostavka haqi (jami)" value={formatSom(o.fare ?? 0)} strong />
                  <Row label="Platforma komissiyasi" value={formatSom(o.commission ?? 0)} color="var(--amber)" />
                  <Row label="Haydovchi daromadi" value={formatSom(o.driverEarning ?? 0)} color="var(--green)" />
                  <Row label="To'lov turi" value={o.paymentType} />
                </div>
              </div>
            </>
          )}

          {o.rating != null && (
            <div className="card">
              <div className="card-header"><span className="card-title">⭐ Baho</span></div>
              <div className="card-body">
                <div style={{ fontSize: 20, color: 'var(--amber)' }}>
                  {'★'.repeat(o.rating)}{'☆'.repeat(5 - o.rating)} <span style={{ fontSize: 14, color: 'var(--text-3)' }}>{o.rating}/5</span>
                </div>
                {o.ratingComment && <div style={{ marginTop: 8, fontSize: 13.5, color: 'var(--text-3)', fontStyle: 'italic' }}>&quot;{o.ratingComment}&quot;</div>}
              </div>
            </div>
          )}
        </div>

        {/* O'ng: holat tarixi */}
        <div className="card" style={{ alignSelf: 'start' }}>
          <div className="card-header">
            <span className="card-title">🕓 Holat tarixi</span>
            <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--text)' }}>{formatSom(total ?? 0)}</span>
          </div>
          <div className="card-body">
            <Timeline history={o.statusHistory} />
          </div>
        </div>
      </div>
    </div>
  );
}
