'use client';

import { useRouter } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import { cancelOrder, deleteOrder, formatDate, formatSom, getOrders, getReportRange } from '@/lib/api';
import { ORDER_STATUSES, statusColor, statusLabel } from '@/lib/status';
import { useToast } from '@/components/toast';
import type { AdminOrder, OrdersQuery, ReportRange } from '@/lib/types';

const VERTICAL_LABEL: Record<string, string> = {
  FOOD: '🍽️ Ovqat',
  TAXI: '🚕 Taksi',
  PARCEL: '📦 Dostavka',
};

const VERTICALS = ['', 'FOOD', 'TAXI', 'PARCEL'];
const VERTICAL_CHIP: Record<string, string> = {
  '': 'Hammasi',
  FOOD: '🍽️ Ovqat',
  TAXI: '🚕 Taksi',
  PARCEL: '📦 Dostavka',
};

type Preset = 'day' | 'week' | 'month' | 'custom';

/** Bir so'rovda nechta buyurtma yuklanadi (server chegarasi — 50). */
const ORDERS_PAGE_SIZE = 25;

function todayKey(): string {
  return new Date().toISOString().slice(0, 10);
}

function StatCard({ label, value, color, icon }: { label: string; value: string; color: string; icon: string }) {
  return (
    <div className="stat-card">
      <div className="stat-label">
        <span>{icon}</span>
        {label}
      </div>
      <div className="stat-value" style={{ color }}>{value}</div>
    </div>
  );
}

function DailyChart({ report }: { report: ReportRange }) {
  const max = Math.max(1, ...report.daily.map((d) => d.orders));
  return (
    <div>
      <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: 14 }}>
        Kunlik buyurtmalar
      </div>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 4, height: 130, padding: '0 0 24px', position: 'relative' }}>
        {report.daily.map((d) => {
          const h = (d.orders / max) * 100;
          return (
            <div
              key={d.date}
              title={`${d.date}: ${d.orders} ta · ${formatSom(d.revenue)}`}
              style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, height: '100%', justifyContent: 'flex-end' }}
            >
              <div style={{ fontSize: 10, color: 'var(--text-muted)', fontWeight: 600 }}>
                {d.orders > 0 ? d.orders : ''}
              </div>
              <div
                style={{
                  width: '100%',
                  height: `${h}%`,
                  minHeight: d.orders > 0 ? 4 : 0,
                  background: 'var(--primary)',
                  borderRadius: '4px 4px 0 0',
                  opacity: 0.85,
                  transition: 'height 0.3s ease',
                }}
              />
              <div
                style={{
                  fontSize: 9.5,
                  color: 'var(--text-muted)',
                  position: 'absolute',
                  bottom: 0,
                  transform: 'rotate(-40deg) translateX(-4px)',
                  transformOrigin: 'center',
                  whiteSpace: 'nowrap',
                  lineHeight: 1,
                }}
              >
                {d.date.slice(5)}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default function OrdersPage() {
  const toast = useToast();
  const router = useRouter();

  // Davr (kun/hafta/oy/ixtiyoriy) — standart: bugun.
  const [preset, setPreset] = useState<Preset>('day');
  const [from, setFrom] = useState(todayKey());
  const [to, setTo] = useState(todayKey());
  const [monthInput, setMonthInput] = useState(todayKey().slice(0, 7));

  const [report, setReport] = useState<ReportRange | null>(null);
  const [reportLoading, setReportLoading] = useState(true);

  const [orders, setOrders] = useState<AdminOrder[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loadingMore, setLoadingMore] = useState(false);
  const [type, setType] = useState<string>('');
  const [status, setStatus] = useState<string>('');
  const [q, setQ] = useState('');
  const [sort, setSort] = useState<'createdAt' | 'total'>('createdAt');
  const [order, setOrder] = useState<'asc' | 'desc'>('desc');
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<string | null>(null);

  function applyPreset(p: 'day' | 'week' | 'month') {
    setPreset(p);
    const today = todayKey();
    if (p === 'day') {
      setFrom(today);
      setTo(today);
    } else if (p === 'week') {
      const d = new Date();
      d.setDate(d.getDate() - 6);
      setFrom(d.toISOString().slice(0, 10));
      setTo(today);
    } else {
      const d = new Date();
      const first = new Date(d.getFullYear(), d.getMonth(), 1);
      setFrom(first.toISOString().slice(0, 10));
      setTo(today);
    }
  }

  function applyMonth(value: string) {
    setMonthInput(value);
    setPreset('custom');
    if (!value) return;
    const [y, m] = value.split('-').map(Number);
    const first = new Date(y, m - 1, 1);
    const last = new Date(y, m, 0);
    setFrom(first.toISOString().slice(0, 10));
    setTo(last.toISOString().slice(0, 10));
  }

  function applyCustomFrom(value: string) {
    setPreset('custom');
    setFrom(value);
  }
  function applyCustomTo(value: string) {
    setPreset('custom');
    setTo(value);
  }

  const loadReport = useCallback(async () => {
    setReportLoading(true);
    try {
      setReport(await getReportRange(from, to));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setReportLoading(false);
    }
  }, [from, to, toast]);

  /**
   * Buyurtmalarni sahifalab yuklaydi. `append=false` — filtr o'zgardi,
   * ro'yxat boshidan; `append=true` — "Yana ko'rsatish". Hech qachon butun
   * jadval tortilmaydi: bir so'rovda faqat ORDERS_PAGE_SIZE ta qator.
   */
  const loadOrders = useCallback(
    async (targetPage = 1, append = false) => {
      if (append) setLoadingMore(true);
      else setLoading(true);
      try {
        const query: OrdersQuery = {
          type: type || undefined,
          status: status || undefined,
          from,
          to,
          q: q.trim() || undefined,
          sort,
          order,
          page: targetPage,
          pageSize: ORDERS_PAGE_SIZE,
        };
        const res = await getOrders(query);
        setOrders((prev) => (append ? [...prev, ...res.items] : res.items));
        setTotal(res.total);
        setPage(res.page);
      } catch (e) {
        toast((e as Error).message, 'error');
      } finally {
        setLoading(false);
        setLoadingMore(false);
      }
    },
    [type, status, from, to, q, sort, order, toast],
  );

  useEffect(() => { loadReport(); }, [loadReport]);
  // Filtr/saralash o'zgarsa — doim 1-sahifadan boshlanadi.
  useEffect(() => { loadOrders(1, false); }, [loadOrders]);

  async function handleCancel(id: string, e: React.MouseEvent) {
    e.stopPropagation();
    if (!confirm('Buyurtmani bekor qilasizmi?')) return;
    setCancelling(id);
    try {
      await cancelOrder(id);
      toast('Buyurtma bekor qilindi', 'success');
      loadOrders();
      loadReport();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setCancelling(null);
    }
  }

  /**
   * Ro'yxatdan o'chirish — yashirin o'chirish (yozuv bazada qoladi).
   * Hisobotlar o'zgarmasligi ataylab: o'tmishdagi tushum/foyda raqamlari
   * keyinchalik "kamayib qolmasligi" kerak.
   */
  async function handleDelete(id: string, publicNo: number, e: React.MouseEvent) {
    e.stopPropagation();
    if (
      !confirm(
        `#${publicNo} buyurtmani ro'yxatdan o'chirasizmi?\n\n` +
          "Yozuv bazada saqlanib qoladi — hisobot raqamlari o'zgarmaydi, " +
          "faqat ro'yxatda ko'rinmay qoladi.",
      )
    ) {
      return;
    }
    setDeleting(id);
    try {
      await deleteOrder(id);
      toast("Buyurtma ro'yxatdan o'chirildi", 'success');
      setOrders((prev) => prev.filter((o) => o.id !== id));
      setTotal((t) => Math.max(0, t - 1));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setDeleting(null);
    }
  }

  const periodLabel =
    preset === 'day' ? 'Bugun' : preset === 'week' ? 'Oxirgi 7 kun' : preset === 'month' ? 'Shu oy' : `${from} — ${to}`;

  return (
    <div className="container">
      {/* Header */}
      <div className="page-header">
        <div>
          <h1 className="page-title">Buyurtmalar</h1>
          <p className="page-subtitle">{periodLabel}</p>
        </div>
      </div>

      {/* Davr tanlash */}
      <div className="card" style={{ marginBottom: 16 }}>
        <div className="card-body" style={{ paddingTop: 14, paddingBottom: 14 }}>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'flex-end' }}>
            <div style={{ display: 'flex', gap: 4 }}>
              <button className={`chip ${preset === 'day' ? 'active' : ''}`} onClick={() => applyPreset('day')}>
                Kunlik
              </button>
              <button className={`chip ${preset === 'week' ? 'active' : ''}`} onClick={() => applyPreset('week')}>
                Haftalik
              </button>
              <button className={`chip ${preset === 'month' ? 'active' : ''}`} onClick={() => applyPreset('month')}>
                Oylik
              </button>
            </div>
            <div style={{ width: 1, alignSelf: 'stretch', background: 'var(--border)' }} />
            <div>
              <label>Dan</label>
              <input type="date" value={from} onChange={(e) => applyCustomFrom(e.target.value)} />
            </div>
            <div>
              <label>Gacha</label>
              <input type="date" value={to} onChange={(e) => applyCustomTo(e.target.value)} />
            </div>
            <div>
              <label>Yoki oy tanlang</label>
              <input type="month" value={monthInput} onChange={(e) => applyMonth(e.target.value)} />
            </div>
          </div>
        </div>
      </div>

      {/* Davr statistikasi */}
      <div className="card" style={{ marginBottom: 20 }}>
        <div className="card-header">
          <span className="card-title">📊 Davr statistikasi</span>
        </div>
        <div className="card-body">
          {reportLoading ? (
            <div className="stats">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="stat-card">
                  <div className="sk sk-line sk-line-sm" style={{ marginBottom: 8 }} />
                  <div className="sk sk-line" style={{ height: 22, width: '60%' }} />
                </div>
              ))}
            </div>
          ) : report ? (
            <>
              <div className="stats" style={{ marginBottom: 20 }}>
                <StatCard label="Buyurtmalar" value={String(report.summary.totalOrders)} color="#3b82f6" icon="📦" />
                <StatCard label="Yetkazilgan" value={String(report.summary.delivered)} color="#16a34a" icon="✅" />
                <StatCard label="Bekor qilingan" value={String(report.summary.cancelled)} color="#dc2626" icon="❌" />
                <StatCard label="Aylanma" value={formatSom(report.summary.revenue)} color="#16a34a" icon="💰" />
                <StatCard label="Foyda" value={formatSom(report.summary.profit)} color="#0891b2" icon="📈" />
                <StatCard label="O'rtacha chek" value={formatSom(report.summary.avgOrder)} color="#8b5cf6" icon="🧾" />
              </div>
              <div style={{ marginBottom: 20 }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: 10 }}>
                  Yo&apos;nalish bo&apos;yicha
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 12 }}>
                  {(
                    [
                      ['food', '🍽️', 'Ovqat', '#ea580c'],
                      ['taxi', '🚕', 'Taksi', '#d97706'],
                      ['parcel', '📦', 'Dostavka', '#3b82f6'],
                    ] as const
                  ).map(([key, icon, label, color]) => (
                    <div
                      key={key}
                      style={{ background: 'var(--surface-2)', border: '1px solid var(--border)', borderRadius: 10, padding: '14px 16px', borderLeft: `3px solid ${color}` }}
                    >
                      <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-2)', marginBottom: 8 }}>
                        {icon} {label}
                      </div>
                      <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--text)' }}>{formatSom(report.byVertical[key].revenue)}</div>
                      <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 3 }}>
                        Foyda: {formatSom(report.byVertical[key].profit)} · {report.byVertical[key].delivered} ta
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              {report.daily.length > 1 && <DailyChart report={report} />}
            </>
          ) : null}
        </div>
      </div>

      {/* Vertical type chips */}
      <div className="filters" style={{ marginBottom: 4 }}>
        {VERTICALS.map((v) => (
          <button key={v} className={`chip ${type === v ? 'active' : ''}`} onClick={() => setType(v)}>
            {VERTICAL_CHIP[v]}
          </button>
        ))}
      </div>

      {/* Status chips */}
      <div className="filters">
        <button className={`chip ${status === '' ? 'active' : ''}`} onClick={() => setStatus('')}>
          Barcha holat
        </button>
        {ORDER_STATUSES.map((s) => (
          <button key={s} className={`chip ${status === s ? 'active' : ''}`} onClick={() => setStatus(s)}>
            {statusLabel(s)}
          </button>
        ))}
      </div>

      {/* Qidiruv + saralash */}
      <div className="card" style={{ marginBottom: 16, marginTop: 12 }}>
        <div className="card-body" style={{ paddingTop: 14, paddingBottom: 14 }}>
          <div className="form-row">
            <div style={{ flex: 2, minWidth: 200 }}>
              <label>Qidiruv (№ yoki manzil)</label>
              <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="#12 yoki ko'cha nomi…" />
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
          </div>
        </div>
      </div>

      {/* Table */}
      {loading ? (
        <div className="card">
          {[...Array(8)].map((_, i) => (
            <div key={i} className="sk sk-row" style={{ margin: '4px 12px', borderRadius: 6 }} />
          ))}
        </div>
      ) : orders.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">📋</div>
            <div className="empty-title">Bu davrda buyurtma topilmadi</div>
            <div className="empty-desc">Filtrlarni yoki davrni o&apos;zgartirib ko&apos;ring</div>
          </div>
        </div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>№</th>
                <th>Tur</th>
                <th>Holat</th>
                <th>Summa</th>
                <th>Manzil</th>
                <th>Sana</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => {
                const active = !['DELIVERED', 'CANCELLED', 'FAILED', 'COMPLETED'].includes(o.status);
                return (
                  <tr
                    key={o.id}
                    onClick={() => router.push(`/orders/${o.id}?type=${o.type}`)}
                    style={{ cursor: 'pointer' }}
                  >
                    <td>
                      <span style={{ fontWeight: 700, color: 'var(--text)' }}>#{o.publicNo}</span>
                    </td>
                    <td>
                      <span style={{ fontSize: 13, color: 'var(--text-3)' }}>{VERTICAL_LABEL[o.type] ?? o.type}</span>
                    </td>
                    <td>
                      <span className="badge" style={{ background: statusColor(o.status), fontSize: 12, padding: '4px 10px' }}>
                        {statusLabel(o.status)}
                      </span>
                    </td>
                    <td>
                      <span style={{ fontWeight: 600, color: 'var(--text)' }}>{formatSom(o.total)}</span>
                    </td>
                    <td>
                      <span
                        style={{
                          color: 'var(--text-3)',
                          fontSize: 13,
                          maxWidth: 260,
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                          display: 'block',
                        }}
                      >
                        {o.address?.text ?? '—'}
                      </span>
                    </td>
                    <td>
                      <span style={{ color: 'var(--text-muted)', fontSize: 12.5 }}>{formatDate(o.createdAt)}</span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: 6, justifyContent: 'flex-end' }}>
                        {active ? (
                          <button
                            className="btn ghost btn-sm"
                            disabled={cancelling === o.id}
                            onClick={(e) => handleCancel(o.id, e)}
                            style={{ color: 'var(--red)', borderColor: 'var(--red)', opacity: cancelling === o.id ? 0.5 : 1 }}
                          >
                            Bekor
                          </button>
                        ) : (
                          // Faqat yakunlangan/bekor qilingan buyurtmani ro'yxatdan
                          // olib tashlash mumkin (yashirin o'chirish).
                          <button
                            className="btn ghost btn-sm"
                            title="Ro'yxatdan o'chirish (hisobotga ta'sir qilmaydi)"
                            aria-label="Buyurtmani ro'yxatdan o'chirish"
                            disabled={deleting === o.id}
                            onClick={(e) => handleDelete(o.id, o.publicNo, e)}
                            style={{ color: 'var(--text-muted)', opacity: deleting === o.id ? 0.5 : 1 }}
                          >
                            {deleting === o.id ? '…' : '🗑'}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Sahifalash — ro'yxat hech qachon bittada to'liq yuklanmaydi */}
      {!loading && total > 0 && (
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            gap: 12,
            marginTop: 14,
            flexWrap: 'wrap',
          }}
        >
          <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            {orders.length} / <b style={{ color: 'var(--text)' }}>{total}</b> ta buyurtma
          </span>
          {orders.length < total && (
            <button className="btn ghost" disabled={loadingMore} onClick={() => loadOrders(page + 1, true)}>
              {loadingMore ? 'Yuklanmoqda…' : `Yana ko'rsatish (${total - orders.length} ta qoldi)`}
            </button>
          )}
        </div>
      )}
    </div>
  );
}
