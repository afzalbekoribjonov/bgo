'use client';

import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import {
  blockDriver,
  cancelOrder,
  formatDate,
  formatSom,
  getDriver,
  getDriverHistory,
  getDriverStats,
  getOrders,
  regenerateDriverCode,
  sendDriverMessage,
  topupDriver,
  unblockDriver,
  updateDriver,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import { statusColor, statusLabel } from '@/lib/status';
import type { AdminDriver, AdminOrder, DriverOrderHistoryItem, DriverStats } from '@/lib/types';

const VERTICAL_ICON: Record<string, string> = { FOOD: '🍽️', TAXI: '🚕', PARCEL: '📦' };

const PERIOD_LABELS = { today: 'Bugun', week: 'Hafta', month: 'Oy', all: 'Butun tarix' } as const;

const DURATION_PRESETS: { label: string; minutes: number }[] = [
  { label: '1 soat', minutes: 60 },
  { label: '6 soat', minutes: 360 },
  { label: '1 kun', minutes: 1440 },
  { label: '3 kun', minutes: 4320 },
  { label: '7 kun', minutes: 10080 },
  { label: '30 kun', minutes: 43200 },
];

function isBlockedNow(d: Pick<AdminDriver, 'blockedUntil'> | null): boolean {
  return !!d?.blockedUntil && new Date(d.blockedUntil).getTime() > Date.now();
}

type Tab = 'info' | 'orders' | 'stats' | 'control';

/** Haydovchi tarixi bir so'rovda nechta qator yuklaydi (server chegarasi — 50). */
const HISTORY_PAGE_SIZE = 25;

const ACTOR_LABEL: Record<string, string> = {
  customer: 'Mijoz bekor qildi',
  kitchen: 'Oshxona rad etdi',
  driver: 'Haydovchi voz kechdi',
  admin: 'Admin bekor qildi',
  system: "Kuryer topilmadi (avtomatik)",
};

export default function DriverDetailPage() {
  const params = useParams<{ id: string }>();
  const id = params.id;
  const router = useRouter();
  const toast = useToast();
  const dialog = useDialog();

  const [tab, setTab] = useState<Tab>('info');
  const [driver, setDriver] = useState<AdminDriver | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // Edit form fields
  const [fullName, setFullName] = useState('');
  const [carName, setCarName] = useState('');
  const [carYear, setCarYear] = useState('');
  const [plateNumber, setPlateNumber] = useState('');
  const [licenseInfo, setLicenseInfo] = useState('');
  const [age, setAge] = useState('');
  const [isActive, setIsActive] = useState(true);
  const [isComfort, setIsComfort] = useState(false);
  const [ratingInput, setRatingInput] = useState('');

  // History tab
  const [history, setHistory] = useState<DriverOrderHistoryItem[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [historyTotal, setHistoryTotal] = useState(0);
  const [historyPage, setHistoryPage] = useState(1);
  const [historyMore, setHistoryMore] = useState(false);

  // Stats tab
  const [period, setPeriod] = useState<'today' | 'week' | 'month' | 'all'>('today');
  const [stats, setStats] = useState<DriverStats | null>(null);
  const [statsLoading, setStatsLoading] = useState(false);

  // Active orders (control tab)
  const [activeOrders, setActiveOrders] = useState<AdminOrder[]>([]);
  const [activeLoading, setActiveLoading] = useState(false);
  const [cancelling, setCancelling] = useState<string | null>(null);

  // Shaxsiy xabar yuborish paneli
  const [showMsg, setShowMsg] = useState(false);
  const [msgTitle, setMsgTitle] = useState('');
  const [msgBody, setMsgBody] = useState('');
  const [msgBusy, setMsgBusy] = useState(false);

  // Bloklash paneli
  const [showBlockPanel, setShowBlockPanel] = useState(false);
  const [blockReason, setBlockReason] = useState('');
  const [blockMinutes, setBlockMinutes] = useState(1440);
  const [blockBusy, setBlockBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const d = await getDriver(id);
      setDriver(d);
      setFullName(d.fullName);
      setCarName(d.carName ?? '');
      setCarYear(d.carYear ? String(d.carYear) : '');
      setPlateNumber(d.plateNumber ?? '');
      setLicenseInfo(d.licenseInfo ?? '');
      setAge(d.age ? String(d.age) : '');
      setIsActive(d.isActive);
      setIsComfort(d.isComfort ?? false);
      setRatingInput(String(d.rating ?? 0));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [id, toast]);

  useEffect(() => { load(); }, [load]);

  // MUHIM: order servisi driverId=userId bilan qidiradi (URL id — bu haydovchi
  // PROFIL id'si). Shu sabab tarix/statistika/faol buyurtmalar userId bilan olinadi.
  const driverUserId = driver?.userId;

  useEffect(() => {
    if (tab === 'orders' && driverUserId && history.length === 0) {
      setHistoryLoading(true);
      getDriverHistory(driverUserId, 1, HISTORY_PAGE_SIZE)
        .then((res) => {
          setHistory(res.items);
          setHistoryTotal(res.total);
          setHistoryPage(res.page);
        })
        .catch((e) => toast((e as Error).message, 'error'))
        .finally(() => setHistoryLoading(false));
    }
  }, [tab, driverUserId, history.length, toast]);

  useEffect(() => {
    if (tab === 'stats' && driverUserId) {
      setStatsLoading(true);
      getDriverStats(driverUserId, period)
        .then(setStats)
        .catch((e) => toast((e as Error).message, 'error'))
        .finally(() => setStatsLoading(false));
    }
  }, [tab, period, driverUserId, toast]);

  useEffect(() => {
    if (tab === 'control' && driverUserId) {
      setActiveLoading(true);
      getOrders({ driverId: driverUserId, status: 'ACCEPTED,PENDING,PREPARING,PICKED_UP,IN_PROGRESS,EN_ROUTE' })
        .then((res) => setActiveOrders(res.items))
        .catch((e) => toast((e as Error).message, 'error'))
        .finally(() => setActiveLoading(false));
    }
  }, [tab, id, driverUserId, toast]);

  async function save() {
    setSaving(true);
    try {
      await updateDriver(id, {
        fullName: fullName.trim(),
        carName: carName.trim() || undefined,
        carYear: carYear ? parseInt(carYear, 10) : undefined,
        plateNumber: plateNumber.trim() || undefined,
        licenseInfo: licenseInfo.trim() || undefined,
        age: age ? parseInt(age, 10) : undefined,
        isActive,
        isComfort,
        rating: ratingInput ? parseFloat(ratingInput) : undefined,
      });
      toast('Saqlandi ✓', 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setSaving(false);
    }
  }

  async function regen() {
    const ok = await dialog.confirm(
      "Yangi 8 xonali login kodi generatsiya qilinadi. Eski kod bekor bo'ladi.",
      { title: 'Login kodini yangilash', danger: true },
    );
    if (!ok) return;
    try {
      const updated = await regenerateDriverCode(id);
      setDriver(updated);
      await dialog.alert(`Yangi login kodi: ${updated.loginCode}`, {
        title: 'Yangi kod tayyor',
        code: updated.loginCode,
      });
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  async function topup() {
    const amountStr = await dialog.prompt("Balansga qo'shilishi kerak bo'lgan summa (so'm):", {
      title: "Balansni to'ldirish",
      placeholder: '50000',
    });
    if (!amountStr) return;
    const amount = parseInt(amountStr.replace(/\D/g, ''), 10);
    if (!amount || amount <= 0) { toast("Noto'g'ri summa", 'error'); return; }
    try {
      await topupDriver(id, amount, "Admin to'ldirdi");
      toast(`+${formatSom(amount)} qo'shildi`, 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  /** Shu haydovchiga shaxsiy xabar (ilovadagi qo'ng'iroqchaga boradi). */
  async function sendPersonalMessage() {
    if (!driver || !msgBody.trim()) return;
    setMsgBusy(true);
    try {
      await sendDriverMessage({
        driverUserId: driver.userId,
        title: msgTitle.trim() || undefined,
        body: msgBody.trim(),
      });
      setMsgTitle('');
      setMsgBody('');
      setShowMsg(false);
      toast(`Xabar ${driver.fullName}ga yuborildi`, 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setMsgBusy(false);
    }
  }

  async function submitBlock() {
    if (!driver) return;
    const reason = blockReason.trim();
    if (reason.length < 3) {
      toast('Sabab kamida 3 ta belgidan iborat bo‘lishi kerak', 'error');
      return;
    }
    setBlockBusy(true);
    try {
      const updated = await blockDriver(driver.id, reason, blockMinutes);
      setDriver(updated);
      setShowBlockPanel(false);
      setBlockReason('');
      toast(`${driver.fullName} bloklandi`, 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBlockBusy(false);
    }
  }

  async function doUnblock() {
    if (!driver) return;
    const ok = await dialog.confirm(
      `${driver.fullName} darhol blokdan chiqariladi (masalan ofisda jarima to'langach). Davom etasizmi?`,
      { title: 'Blokdan chiqarish' },
    );
    if (!ok) return;
    setBlockBusy(true);
    try {
      const updated = await unblockDriver(driver.id);
      setDriver(updated);
      toast(`${driver.fullName} blokdan chiqarildi`, 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBlockBusy(false);
    }
  }

  async function handleCancelOrder(oid: string) {
    const ok = await dialog.confirm('Buyurtmani bekor qilasizmi?', { title: 'Buyurtmani bekor qilish', danger: true });
    if (!ok) return;
    setCancelling(oid);
    try {
      await cancelOrder(oid);
      toast('Buyurtma bekor qilindi', 'success');
      setActiveOrders((prev) => prev.filter((o) => o.id !== oid));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setCancelling(null);
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

  if (!driver) {
    return (
      <div className="container">
        <Link href="/drivers" className="btn ghost" style={{ marginBottom: 16 }}>← Haydovchilar</Link>
        <div className="card">
          <div className="empty">
            <div className="empty-icon">🔍</div>
            <div className="empty-title">Haydovchi topilmadi</div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      {/* Breadcrumb */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20 }}>
        <Link href="/drivers" style={{ color: 'var(--text-muted)', textDecoration: 'none', fontSize: 13.5 }}>
          Haydovchilar
        </Link>
        <span style={{ color: 'var(--text-muted)' }}>&rsaquo;</span>
        <span style={{ fontSize: 13.5, color: 'var(--text-2)', fontWeight: 600 }}>{driver.fullName}</span>
      </div>

      {/* Page header */}
      <div className="page-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <div style={{
            width: 52, height: 52, borderRadius: '50%', background: 'var(--primary)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontWeight: 800, fontSize: 22, flexShrink: 0, position: 'relative',
          }}>
            {driver.fullName.charAt(0).toUpperCase()}
            {driver.isActive && (
              <span style={{
                position: 'absolute', bottom: 2, right: 2, width: 13, height: 13,
                borderRadius: '50%', background: driver.isOnline ? 'var(--green)' : '#94a3b8',
                border: '2.5px solid var(--surface)',
                boxShadow: driver.isOnline ? '0 0 6px var(--green)' : 'none',
              }} />
            )}
          </div>
          <div>
            <h1 className="page-title">{driver.fullName}</h1>
            <div style={{ display: 'flex', gap: 8, marginTop: 4, flexWrap: 'wrap', alignItems: 'center' }}>
              <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>📞 {driver.phone}</span>
              <span style={{ color: 'var(--text-muted)' }}>&middot;</span>
              <span className="badge" style={{
                background: !driver.isActive ? 'var(--red)' : driver.isOnline ? 'var(--green)' : '#64748b',
                fontSize: 11.5,
              }}>
                {!driver.isActive ? 'Nofaol' : driver.isOnline ? 'Online' : 'Offline'}
              </span>
              {isBlockedNow(driver) && (
                <>
                  <span style={{ color: 'var(--text-muted)' }}>&middot;</span>
                  <span className="badge" style={{ background: '#7f1d1d', fontSize: 11.5 }}>🚫 Bloklangan</span>
                </>
              )}
              <span style={{ color: 'var(--text-muted)' }}>&middot;</span>
              <span style={{ fontSize: 12.5, color: 'var(--amber)' }}>
                {'★'.repeat(Math.round(driver.rating ?? 0))}{'☆'.repeat(5 - Math.round(driver.rating ?? 0))} {(driver.rating ?? 0).toFixed(1)}
              </span>
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <button className="btn ghost" onClick={() => setShowMsg((v) => !v)}>
            {showMsg ? '✕ Yopish' : '📨 Xabar yuborish'}
          </button>
          <button className="btn green" onClick={topup}>💳 To&lsquo;ldirish</button>
          <button className="btn red" onClick={regen}>🔄 Kodni yangilash</button>
        </div>
      </div>

      {/* Shaxsiy xabar yuborish */}
      {showMsg && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">📨 {driver.fullName}ga shaxsiy xabar</span>
            <span style={{ fontSize: 12.5, color: 'var(--text-muted)' }}>
              Faqat shu haydovchi ko&apos;radi
            </span>
          </div>
          <div className="card-body">
            <div style={{ display: 'grid', gap: 12, maxWidth: 640 }}>
              <div>
                <label>Sarlavha (ixtiyoriy)</label>
                <input
                  value={msgTitle}
                  onChange={(e) => setMsgTitle(e.target.value)}
                  placeholder="Masalan: Hujjatlar"
                  maxLength={120}
                />
              </div>
              <div>
                <label>Xabar matni *</label>
                <textarea
                  value={msgBody}
                  onChange={(e) => setMsgBody(e.target.value)}
                  placeholder="Xabar matnini yozing…"
                  rows={3}
                  maxLength={2000}
                  style={{ resize: 'vertical' }}
                />
              </div>
              <div>
                <button
                  className="btn"
                  disabled={msgBusy || !msgBody.trim()}
                  onClick={sendPersonalMessage}
                >
                  {msgBusy ? 'Yuborilmoqda…' : '📨 Yuborish'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Quick stat row */}
      <div className="stats" style={{ marginBottom: 16 }}>
        <div className="stat-card" style={{ borderLeft: '3px solid var(--green)' }}>
          <div className="stat-label">💳 Balans</div>
          <div className="stat-value" style={{ color: driver.balance < 0 ? 'var(--red)' : 'var(--green)' }}>
            {formatSom(driver.balance)}
          </div>
        </div>
        <div className="stat-card" style={{ borderLeft: '3px solid var(--primary)' }}>
          <div className="stat-label">🔑 Login kodi</div>
          <div className="stat-value" style={{ fontFamily: 'monospace', fontSize: 26, letterSpacing: '4px', color: 'var(--primary)' }}>
            {driver.loginCode}
          </div>
        </div>
        <div className="stat-card" style={{ borderLeft: '3px solid var(--amber)' }}>
          <div className="stat-label">⭐ Reyting</div>
          <div className="stat-value" style={{ color: 'var(--amber)' }}>
            {(driver.rating ?? 0).toFixed(2)} / 5
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 16, borderBottom: '1px solid var(--border)', paddingBottom: 0 }}>
        {([
          { key: 'info', label: '👤 Ma\'lumotlar' },
          { key: 'orders', label: '📋 Buyurtmalar' },
          { key: 'stats', label: '📊 Statistika' },
          { key: 'control', label: '⚙️ Boshqaruv' },
        ] as { key: Tab; label: string }[]).map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            style={{
              padding: '10px 18px',
              border: 'none',
              borderBottom: tab === key ? '2px solid var(--primary)' : '2px solid transparent',
              background: 'none',
              color: tab === key ? 'var(--primary)' : 'var(--text-muted)',
              fontWeight: tab === key ? 700 : 500,
              fontSize: 14,
              cursor: 'pointer',
              borderRadius: '6px 6px 0 0',
              transition: 'all .15s',
            }}
          >
            {label}
          </button>
        ))}
      </div>

      {/* === TAB: Ma'lumotlar === */}
      {tab === 'info' && (
        <div className="card">
          <div className="card-header">
            <span className="card-title">👤 Shaxsiy ma&lsquo;lumotlar</span>
          </div>
          <div className="card-body">
            <div className="form-grid form-grid-auto" style={{ marginBottom: 16 }}>
              <div>
                <label>To&lsquo;liq ism</label>
                <input value={fullName} onChange={(e) => setFullName(e.target.value)} />
              </div>
              <div>
                <label>Yosh</label>
                <input value={age} inputMode="numeric" placeholder="27" onChange={(e) => setAge(e.target.value.replace(/\D/g, ''))} />
              </div>
              <div>
                <label>Avtomobil</label>
                <input value={carName} onChange={(e) => setCarName(e.target.value)} placeholder="Chevrolet Nexia 3" />
              </div>
              <div>
                <label>Yil</label>
                <input value={carYear} inputMode="numeric" placeholder="2021" onChange={(e) => setCarYear(e.target.value.replace(/\D/g, ''))} />
              </div>
              <div>
                <label>Davlat raqami</label>
                <input value={plateNumber} onChange={(e) => setPlateNumber(e.target.value.toUpperCase())} placeholder="30 A 123 AB" />
              </div>
              <div>
                <label>Litsenziya</label>
                <input value={licenseInfo} onChange={(e) => setLicenseInfo(e.target.value)} placeholder="AA123456" />
              </div>
              <div>
                <label>Reyting (0–5)</label>
                <input
                  value={ratingInput}
                  type="number"
                  min={0}
                  max={5}
                  step={0.1}
                  onChange={(e) => setRatingInput(e.target.value)}
                  placeholder="4.5"
                />
              </div>
              <div>
                <label>Holat</label>
                <button
                  className={`btn ${isActive ? 'green' : 'red'}`}
                  style={{ width: '100%', justifyContent: 'center' }}
                  onClick={() => setIsActive((v) => !v)}
                >
                  {isActive ? '✅ Faol' : '🔴 Nofaol'}
                </button>
              </div>
              <div>
                <label>Tarif klassi</label>
                <button
                  className={`btn ${isComfort ? '' : 'ghost'}`}
                  style={{
                    width: '100%',
                    justifyContent: 'center',
                    ...(isComfort
                      ? { background: 'linear-gradient(135deg, #7048e8, #9775fa)' }
                      : {}),
                  }}
                  onClick={() => setIsComfort((v) => !v)}
                  title="Comfort tarifini faqat admin yoqadi — Comfort buyurtmalar shu mashinalarga boradi"
                >
                  {isComfort ? '👑 Comfort' : '🚕 Start'}
                </button>
              </div>
            </div>
            <button className="btn" disabled={saving} onClick={save}>
              {saving ? (<><span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} /> Saqlanmoqda&hellip;</>) : 'Saqlash'}
            </button>
          </div>
        </div>
      )}

      {/* === TAB: Buyurtmalar tarixi === */}
      {tab === 'orders' && (
        <div>
          {historyLoading ? (
            <div className="card">
              {[...Array(6)].map((_, i) => (
                <div key={i} className="sk sk-row" style={{ margin: '4px 12px', borderRadius: 6 }} />
              ))}
            </div>
          ) : history.length === 0 ? (
            <div className="card">
              <div className="empty">
                <div className="empty-icon">📋</div>
                <div className="empty-title">Buyurtmalar topilmadi</div>
                <div className="empty-desc">Bu haydovchi hali birorta buyurtmani yakunlamagan</div>
              </div>
            </div>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Tur</th>
                    <th>Holat</th>
                    <th>Mijoz</th>
                    <th>Summa</th>
                    <th>Daromad</th>
                    <th>Komissiya</th>
                    <th>Masofa</th>
                    <th>Vaqt</th>
                    <th>Sana</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((h) => (
                    <tr
                      key={h.id}
                      onClick={() => router.push(`/orders/${h.id}?type=${h.type}`)}
                      style={{ cursor: 'pointer' }}
                    >
                      <td>
                        <span style={{ fontSize: 18 }}>{VERTICAL_ICON[h.type] ?? '?'}</span>
                        <span style={{ fontSize: 12, color: 'var(--text-muted)', marginLeft: 4 }}>{h.type}</span>
                      </td>
                      <td>
                        <span className="badge" style={{ background: statusColor(h.status), fontSize: 11.5 }}>
                          {statusLabel(h.status)}
                        </span>
                        {h.cancelledBy && (
                          <div style={{ fontSize: 11, color: 'var(--red)', marginTop: 4, whiteSpace: 'nowrap' }}>
                            {ACTOR_LABEL[h.cancelledBy] ?? h.cancelledBy}
                          </div>
                        )}
                      </td>
                      <td>
                        <div style={{ fontSize: 13 }}>{h.customerName ?? '—'}</div>
                        {h.customerPhone && (
                          <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>{h.customerPhone}</div>
                        )}
                      </td>
                      <td style={{ fontWeight: 600 }}>{formatSom(h.total ?? 0)}</td>
                      <td style={{ color: 'var(--green)', fontWeight: 600 }}>{formatSom(h.earning ?? 0)}</td>
                      <td style={{ color: 'var(--amber)', fontSize: 13 }}>{h.commission != null ? formatSom(h.commission) : '—'}</td>
                      <td style={{ fontSize: 13, color: 'var(--text-muted)' }}>
                        {h.distanceKm != null ? `${h.distanceKm.toFixed(1)} km` : '—'}
                      </td>
                      <td style={{ fontSize: 13, color: 'var(--text-muted)' }}>
                        {h.durationMin != null ? `${h.durationMin} min` : '—'}
                      </td>
                      <td style={{ fontSize: 12, color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                        {formatDate(h.createdAt)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Sahifalash — tarix hech qachon bittada to'liq yuklanmaydi */}
          {!historyLoading && historyTotal > 0 && (
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
                {history.length} / <b style={{ color: 'var(--text)' }}>{historyTotal}</b> ta yozuv
              </span>
              {history.length < historyTotal && driverUserId && (
                <button
                  className="btn ghost"
                  disabled={historyMore}
                  onClick={() => {
                    setHistoryMore(true);
                    getDriverHistory(driverUserId, historyPage + 1, HISTORY_PAGE_SIZE)
                      .then((res) => {
                        setHistory((prev) => [...prev, ...res.items]);
                        setHistoryTotal(res.total);
                        setHistoryPage(res.page);
                      })
                      .catch((e) => toast((e as Error).message, 'error'))
                      .finally(() => setHistoryMore(false));
                  }}
                >
                  {historyMore
                    ? 'Yuklanmoqda…'
                    : `Yana ko'rsatish (${historyTotal - history.length} ta qoldi)`}
                </button>
              )}
            </div>
          )}
        </div>
      )}

      {/* === TAB: Statistika === */}
      {tab === 'stats' && (
        <div>
          <div className="filters" style={{ marginBottom: 16 }}>
            {(['today', 'week', 'month', 'all'] as const).map((p) => (
              <button key={p} className={`chip ${period === p ? 'active' : ''}`} onClick={() => setPeriod(p)}>
                {p === 'all' ? '📜 ' : ''}{PERIOD_LABELS[p]}
              </button>
            ))}
          </div>
          {statsLoading ? (
            <div className="stats">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="stat-card"><div className="sk sk-para" /></div>
              ))}
            </div>
          ) : stats ? (
            <>
              <div className="stats" style={{ marginBottom: 16 }}>
                <div className="stat-card" style={{ borderLeft: '3px solid var(--primary)' }}>
                  <div className="stat-label">📦 Buyurtmalar</div>
                  <div className="stat-value">{stats.orders}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>{PERIOD_LABELS[stats.period]} davomida</div>
                </div>
                <div className="stat-card" style={{ borderLeft: '3px solid var(--green)' }}>
                  <div className="stat-label">💰 Haydovchi daromadi</div>
                  <div className="stat-value" style={{ color: 'var(--green)' }}>{formatSom(stats.earning)}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Umumiy yetkazish haqi</div>
                </div>
                <div className="stat-card" style={{ borderLeft: '3px solid var(--amber)' }}>
                  <div className="stat-label">🏦 Platforma foydasi</div>
                  <div className="stat-value" style={{ color: 'var(--amber)' }}>{formatSom(stats.profit)}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Xizmat komissiyasi</div>
                </div>
              </div>
              {stats.orders > 0 ? (
                <>
                  <div className="card" style={{ marginBottom: 16 }}>
                    <div className="card-body">
                      <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
                        <div>
                          <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 4 }}>O&apos;rtacha daromad</div>
                          <div style={{ fontWeight: 700, fontSize: 18 }}>{formatSom(Math.round(stats.earning / stats.orders))}</div>
                        </div>
                        <div>
                          <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 4 }}>O&apos;rtacha komissiya</div>
                          <div style={{ fontWeight: 700, fontSize: 18, color: 'var(--amber)' }}>{formatSom(Math.round(stats.profit / stats.orders))}</div>
                        </div>
                        <div>
                          <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 4 }}>Daromad ulushi</div>
                          <div style={{ fontWeight: 700, fontSize: 18 }}>
                            {stats.earning + stats.profit > 0
                              ? `${Math.round((stats.earning / (stats.earning + stats.profit)) * 100)}%`
                              : '—'}
                          </div>
                        </div>
                        {stats.cancelled != null && stats.cancelled > 0 && (
                          <div>
                            <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 4 }}>Bekor qilingan</div>
                            <div style={{ fontWeight: 700, fontSize: 18, color: 'var(--red)' }}>{stats.cancelled}</div>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {stats.byVertical && (
                    <div>
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
                            <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--text)' }}>{stats.byVertical![key].orders} ta</div>
                            <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 3 }}>
                              Daromad: {formatSom(stats.byVertical![key].earning)}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </>
              ) : (
                <div className="card">
                  <div className="empty" style={{ padding: '32px 0' }}>
                    <div className="empty-icon">📊</div>
                    <div className="empty-title">
                      {period === 'all'
                        ? 'Bu haydovchi hali birorta buyurtmani yakunlamagan'
                        : `${PERIOD_LABELS[period]} davomida yakunlangan buyurtma yo'q`}
                    </div>
                    {period !== 'all' && (
                      <div className="empty-desc">
                        Butun faoliyat davomidagi statistika uchun{' '}
                        <button className="btn ghost sm" style={{ display: 'inline-flex' }} onClick={() => setPeriod('all')}>
                          📜 Butun tarix
                        </button>
                        {' '}ni tanlang
                      </div>
                    )}
                  </div>
                </div>
              )}
            </>
          ) : null}
        </div>
      )}

      {/* === TAB: Boshqaruv === */}
      {tab === 'control' && (
        <div>
          <div className="card" style={{ marginBottom: 16 }}>
            <div className="card-header">
              <span className="card-title">🚫 Bloklash</span>
            </div>
            <div className="card-body">
              {isBlockedNow(driver) ? (
                <>
                  <div className="info-block red" style={{ marginBottom: 12, fontSize: 13 }}>
                    🚫 Bloklangan — {driver.blockedUntil ? formatDate(driver.blockedUntil) : '—'} gacha.
                    {driver.blockReason ? ` Sabab: ${driver.blockReason}` : ''}
                    <br />Darhol chiqish uchun haydovchi ofisga kelib jarima to&apos;lashi kerak.
                  </div>
                  <button className="btn green" disabled={blockBusy} onClick={doUnblock}>
                    {blockBusy ? '…' : '✅ Blokdan darhol chiqarish'}
                  </button>
                </>
              ) : showBlockPanel ? (
                <div style={{ maxWidth: 480 }}>
                  <label>Bloklash sababi *</label>
                  <textarea
                    value={blockReason}
                    onChange={(e) => setBlockReason(e.target.value)}
                    placeholder="Masalan: ketma-ket buyurtmalarni bekor qilish"
                    rows={2}
                    maxLength={500}
                    style={{ resize: 'vertical', width: '100%', marginBottom: 10 }}
                  />
                  <label>Muddat</label>
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 12 }}>
                    {DURATION_PRESETS.map((p) => (
                      <button
                        key={p.minutes}
                        className={`chip ${blockMinutes === p.minutes ? 'active' : ''}`}
                        onClick={() => setBlockMinutes(p.minutes)}
                        type="button"
                      >
                        {p.label}
                      </button>
                    ))}
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button className="btn red" disabled={blockBusy} onClick={submitBlock}>
                      {blockBusy ? 'Bloklanmoqda…' : 'Bloklash'}
                    </button>
                    <button className="btn ghost" onClick={() => setShowBlockPanel(false)}>Bekor qilish</button>
                  </div>
                </div>
              ) : (
                <button className="btn red" onClick={() => setShowBlockPanel(true)}>
                  🚫 Vaqtinchalik bloklash
                </button>
              )}
            </div>
          </div>

          <div className="card">
            <div className="card-header">
              <span className="card-title">⚡ Faol buyurtmalar</span>
              <button className="btn ghost btn-sm" disabled={!driverUserId} onClick={() => {
                if (!driverUserId) return;
                setActiveLoading(true);
                getOrders({ driverId: driverUserId, pageSize: 50 })
                  .then((res) =>
                    setActiveOrders(
                      res.items.filter(
                        (o) => !['DELIVERED', 'CANCELLED', 'FAILED', 'COMPLETED'].includes(o.status),
                      ),
                    ),
                  )
                  .catch((e) => toast((e as Error).message, 'error'))
                  .finally(() => setActiveLoading(false));
              }}>
                ↺ Yangilash
              </button>
            </div>
            <div className="card-body">
              {activeLoading ? (
                <div>{[...Array(3)].map((_, i) => <div key={i} className="sk sk-row" style={{ marginBottom: 8, borderRadius: 6 }} />)}</div>
              ) : activeOrders.length === 0 ? (
                <div className="empty" style={{ padding: '24px 0' }}>
                  <div className="empty-icon">✅</div>
                  <div className="empty-title">Faol buyurtmalar yo&lsquo;q</div>
                  <div className="empty-desc">Haydovchi hozir bo&lsquo;sh</div>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {activeOrders.map((o) => (
                    <div key={o.id} style={{
                      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                      padding: '12px 16px', borderRadius: 8, background: 'var(--surface-2)',
                      border: '1px solid var(--border)',
                    }}>
                      <div>
                        <div style={{ fontWeight: 700, fontSize: 15 }}>#{o.publicNo}</div>
                        <div style={{ fontSize: 12.5, color: 'var(--text-muted)', marginTop: 2 }}>
                          {o.address?.text ?? '—'} &middot; {formatDate(o.createdAt)}
                        </div>
                      </div>
                      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                        <span className="badge" style={{ background: statusColor(o.status), fontSize: 11.5 }}>
                          {statusLabel(o.status)}
                        </span>
                        <span style={{ fontWeight: 700 }}>{formatSom(o.total)}</span>
                        <button
                          className="btn ghost btn-sm"
                          disabled={cancelling === o.id}
                          onClick={() => handleCancelOrder(o.id)}
                          style={{ color: 'var(--red)', borderColor: 'var(--red)' }}
                        >
                          {cancelling === o.id ? '…' : 'Bekor'}
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
