'use client';

import Link from 'next/link';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { blockDriver, formatDate, getDrivers, getSuspiciousDrivers, sendDriverMessage, unblockDriver } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import type {
  AdminDriver,
  CancellationFlaggedDriver,
  SuspiciousDriverGroup,
  SuspiciousDriversResponse,
  SuspiciousTrip,
} from '@/lib/types';

const TYPE_LABEL: Record<SuspiciousTrip['type'], string> = {
  FOOD: 'Ovqat',
  TAXI: 'Taksi',
  PARCEL: 'Dostavka',
};

const DURATION_PRESETS: { label: string; minutes: number }[] = [
  { label: '1 soat', minutes: 60 },
  { label: '6 soat', minutes: 360 },
  { label: '1 kun', minutes: 1440 },
  { label: '3 kun', minutes: 4320 },
  { label: '7 kun', minutes: 10080 },
  { label: '30 kun', minutes: 43200 },
];

function isBlockedNow(d: AdminDriver | undefined): boolean {
  return !!d?.blockedUntil && new Date(d.blockedUntil).getTime() > Date.now();
}

export default function SuspiciousDriversPage() {
  const toast = useToast();
  const dialog = useDialog();

  const [data, setData] = useState<SuspiciousDriversResponse>({ speedFlagged: [], cancellationFlagged: [] });
  const [drivers, setDrivers] = useState<AdminDriver[]>([]);
  const [loading, setLoading] = useState(true);
  const [openId, setOpenId] = useState<string | null>(null);

  // Bloklash paneli (bitta driverId uchun ochiladi)
  const [blockPanelFor, setBlockPanelFor] = useState<string | null>(null);
  const [blockReason, setBlockReason] = useState('');
  const [blockMinutes, setBlockMinutes] = useState(1440);
  const [busy, setBusy] = useState<string | null>(null);

  const driversById = useMemo(() => new Map(drivers.map((d) => [d.userId, d])), [drivers]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [suspicious, driverList] = await Promise.all([getSuspiciousDrivers(), getDrivers()]);
      setData(suspicious);
      setDrivers(driverList);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => { load(); }, [load]);

  function openBlockPanel(driverId: string) {
    setBlockPanelFor(driverId);
    setBlockReason('');
    setBlockMinutes(1440);
  }

  async function submitBlock(driverId: string) {
    const driver = driversById.get(driverId);
    if (!driver) return;
    const reason = blockReason.trim();
    if (reason.length < 3) {
      toast('Sabab kamida 3 ta belgidan iborat bo‘lishi kerak', 'error');
      return;
    }
    setBusy(driverId);
    try {
      const updated = await blockDriver(driver.id, reason, blockMinutes);
      setDrivers((prev) => prev.map((d) => (d.id === updated.id ? { ...d, ...updated } : d)));
      setBlockPanelFor(null);
      toast(`${driver.fullName} bloklandi`, 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(null);
    }
  }

  async function doUnblock(driverId: string) {
    const driver = driversById.get(driverId);
    if (!driver) return;
    const ok = await dialog.confirm(
      `${driver.fullName} darhol blokdan chiqariladi (masalan ofisda jarima to'langach). Davom etasizmi?`,
      { title: 'Blokdan chiqarish' },
    );
    if (!ok) return;
    setBusy(driverId);
    try {
      const updated = await unblockDriver(driver.id);
      setDrivers((prev) => prev.map((d) => (d.id === updated.id ? { ...d, ...updated } : d)));
      toast(`${driver.fullName} blokdan chiqarildi`, 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(null);
    }
  }

  async function doWarn(driverId: string) {
    const driver = driversById.get(driverId);
    if (!driver) return;
    const text = await dialog.prompt('Ogohlantirish matnini yozing:', {
      title: `${driver.fullName}ga ogohlantirish`,
      placeholder: "Diqqat: buyurtmalarni ketma-ket bekor qilish tekshirilmoqda...",
    });
    if (!text?.trim()) return;
    setBusy(driverId);
    try {
      await sendDriverMessage({ driverUserId: driverId, title: 'Ogohlantirish', body: text.trim() });
      toast(`Ogohlantirish ${driver.fullName}ga yuborildi`, 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(null);
    }
  }

  function driverLink(driverId: string) {
    const pid = driversById.get(driverId)?.id;
    return pid ? `/drivers/${pid}` : undefined;
  }

  function renderControlPanel(driverId: string) {
    const driver = driversById.get(driverId);
    const blocked = isBlockedNow(driver);
    const isBusy = busy === driverId;

    return (
      <div style={{ marginTop: 10, paddingTop: 10, borderTop: '1px dashed var(--border)' }}>
        {blocked && driver && (
          <div className="info-block red" style={{ marginBottom: 10, fontSize: 12.5 }}>
            🚫 Bloklangan — {driver.blockedUntil ? formatDate(driver.blockedUntil) : '—'} gacha.
            {driver.blockReason ? ` Sabab: ${driver.blockReason}` : ''}
          </div>
        )}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <button className="btn ghost btn-sm" disabled={isBusy || !driver} onClick={() => doWarn(driverId)}>
            ⚠️ Ogohlantirish
          </button>
          {blocked ? (
            <button className="btn ghost btn-sm" disabled={isBusy || !driver} style={{ color: 'var(--green)', borderColor: 'var(--green)' }} onClick={() => doUnblock(driverId)}>
              {isBusy ? '…' : '✅ Blokdan chiqarish'}
            </button>
          ) : (
            <button className="btn ghost btn-sm" disabled={isBusy || !driver} style={{ color: 'var(--red)', borderColor: 'var(--red)' }} onClick={() => openBlockPanel(driverId)}>
              🚫 Bloklash
            </button>
          )}
        </div>

        {blockPanelFor === driverId && (
          <div style={{ marginTop: 10, padding: 12, background: 'var(--surface-2)', border: '1px solid var(--border)', borderRadius: 8 }}>
            <label>Bloklash sababi *</label>
            <textarea
              value={blockReason}
              onChange={(e) => setBlockReason(e.target.value)}
              placeholder="Masalan: ketma-ket 5 marta buyurtmani bekor qildi"
              rows={2}
              maxLength={500}
              style={{ resize: 'vertical', width: '100%', marginBottom: 10 }}
            />
            <label>Muddat</label>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 10 }}>
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
              <button className="btn red btn-sm" disabled={isBusy} onClick={() => submitBlock(driverId)}>
                {isBusy ? 'Bloklanmoqda…' : `🚫 ${DURATION_PRESETS.find((p) => p.minutes === blockMinutes)?.label ?? ''}ga bloklash`}
              </button>
              <button className="btn ghost btn-sm" onClick={() => setBlockPanelFor(null)}>Bekor qilish</button>
            </div>
          </div>
        )}
      </div>
    );
  }

  const totalCount = data.speedFlagged.length + data.cancellationFlagged.length;

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Shubhali haydovchilar</h1>
          <p className="page-subtitle">
            Real bo&apos;lmagan tezlik yoki ketma-ket bekor qilishlar — tekshirish va nazorat paneli
          </p>
        </div>
      </div>

      {loading ? (
        <div>
          {[...Array(3)].map((_, i) => (
            <div key={i} className="card" style={{ marginBottom: 8, padding: '16px 20px' }}>
              <div className="sk sk-line" style={{ width: '30%', marginBottom: 8, height: 15 }} />
              <div className="sk sk-line sk-line-md" style={{ height: 12 }} />
            </div>
          ))}
        </div>
      ) : totalCount === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">✅</div>
            <div className="empty-title">Shubhali holat topilmadi</div>
            <div className="empty-desc">Barcha haydovchilar odatiy tartibda ishlamoqda</div>
          </div>
        </div>
      ) : (
        <>
          {/* --- Ketma-ket bekor qilgan haydovchilar --- */}
          <div style={{ fontSize: 12.5, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '0.4px', margin: '4px 0 10px' }}>
            🚫 Ketma-ket bekor qilgan ({data.cancellationFlagged.length})
          </div>
          {data.cancellationFlagged.length === 0 ? (
            <div className="card" style={{ marginBottom: 20 }}>
              <div className="empty" style={{ padding: '20px 0' }}>
                <div className="empty-desc">Hozircha ketma-ket 3tadan ortiq bekor qilgan haydovchi yo&apos;q</div>
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 24 }}>
              {data.cancellationFlagged.map((c: CancellationFlaggedDriver) => {
                const rowId = `c:${c.driverId}`;
                const blocked = isBlockedNow(driversById.get(c.driverId));
                return (
                  <div key={rowId} className="card">
                    <div
                      className="card-header"
                      style={{ cursor: 'pointer' }}
                      onClick={() => setOpenId(openId === rowId ? null : rowId)}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <span style={{ fontSize: 18 }}>🚫</span>
                        <div>
                          <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--text)' }}>
                            {driverLink(c.driverId) ? (
                              <Link href={driverLink(c.driverId)!} onClick={(e) => e.stopPropagation()}>
                                {c.driverName ?? 'Nomaʻlum haydovchi'}
                              </Link>
                            ) : (
                              c.driverName ?? 'Nomaʻlum haydovchi'
                            )}
                          </div>
                          <div style={{ fontSize: 12.5, color: 'var(--text-muted)', marginTop: 2 }}>
                            {[c.carName, c.plateNumber].filter(Boolean).join(' · ') || '—'}
                          </div>
                        </div>
                      </div>
                      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                        {blocked && (
                          <span className="badge" style={{ background: '#7f1d1d', fontSize: 11.5 }}>Bloklangan</span>
                        )}
                        <span className="badge" style={{ background: 'var(--red, #ef4444)', fontSize: 11.5 }}>
                          {c.consecutiveCancellations} marta ketma-ket
                        </span>
                        <span style={{ color: 'var(--text-muted)', transform: openId === rowId ? 'rotate(90deg)' : 'none', transition: 'transform 150ms' }}>›</span>
                      </div>
                    </div>
                    {openId === rowId && (
                      <div className="card-body" style={{ borderTop: '1px solid var(--border)' }}>
                        {renderControlPanel(c.driverId)}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}

          {/* --- Tezlik bo'yicha belgilangan --- */}
          <div style={{ fontSize: 12.5, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '0.4px', margin: '4px 0 10px' }}>
            ⚡ Tezlik bo&apos;yicha belgilangan ({data.speedFlagged.length})
          </div>
          <div className="info-block amber" style={{ marginBottom: 16, fontSize: 13 }}>
            Bu ro&apos;yxat safarning haydovchi GPS&apos;i orqali o&apos;lchangan masofasi va vaqtidan
            avtomatik hisoblanadi. Belgilanish — ayb emas, tekshiruv uchun signal (masalan GPS xatosi
            yoki xato hisobot bo&apos;lishi ham mumkin).
          </div>
          {data.speedFlagged.length === 0 ? (
            <div className="card">
              <div className="empty" style={{ padding: '20px 0' }}>
                <div className="empty-desc">Tezlik bo&apos;yicha belgilangan safar yo&apos;q</div>
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {data.speedFlagged.map((g: SuspiciousDriverGroup) => {
                const rowId = `s:${g.driverId}`;
                const blocked = isBlockedNow(driversById.get(g.driverId));
                return (
                  <div key={rowId} className="card">
                    <div
                      className="card-header"
                      style={{ cursor: 'pointer' }}
                      onClick={() => setOpenId(openId === rowId ? null : rowId)}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <span style={{ fontSize: 18 }}>⚠️</span>
                        <div>
                          <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--text)' }}>
                            {driverLink(g.driverId) ? (
                              <Link href={driverLink(g.driverId)!} onClick={(e) => e.stopPropagation()}>
                                {g.driverName ?? 'Nomaʻlum haydovchi'}
                              </Link>
                            ) : (
                              g.driverName ?? 'Nomaʻlum haydovchi'
                            )}
                          </div>
                          <div style={{ fontSize: 12.5, color: 'var(--text-muted)', marginTop: 2 }}>
                            {[g.carName, g.plateNumber].filter(Boolean).join(' · ') || '—'}
                          </div>
                        </div>
                      </div>
                      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                        {blocked && (
                          <span className="badge" style={{ background: '#7f1d1d', fontSize: 11.5 }}>Bloklangan</span>
                        )}
                        <span className="badge" style={{ background: 'var(--amber, #f59e0b)', fontSize: 11.5 }}>
                          {g.flagCount} ta belgilangan safar
                        </span>
                        <span style={{ color: 'var(--text-muted)', transform: openId === rowId ? 'rotate(90deg)' : 'none', transition: 'transform 150ms' }}>›</span>
                      </div>
                    </div>

                    {openId === rowId && (
                      <div className="card-body" style={{ borderTop: '1px solid var(--border)' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: 8 }}>
                          {g.trips.map((t) => (
                            <div key={t.id} style={{ padding: '10px 12px', background: 'var(--surface-2)', border: '1px solid var(--border)', borderRadius: 8, fontSize: 12.5 }}>
                              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                                <span style={{ fontWeight: 700, color: 'var(--text-2)' }}>
                                  {TYPE_LABEL[t.type]} #{t.publicNo}
                                </span>
                                <span style={{ color: 'var(--text-muted)' }}>
                                  {new Date(t.createdAt).toLocaleDateString('uz-UZ')}
                                </span>
                              </div>
                              <div style={{ color: 'var(--text-muted)' }}>
                                {t.distanceKm.toFixed(1)} km · {t.durationMin} daq
                                {t.speedKmh !== null && ` · ~${t.speedKmh} km/soat`}
                              </div>
                            </div>
                          ))}
                        </div>
                        {renderControlPanel(g.driverId)}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </>
      )}
    </div>
  );
}
