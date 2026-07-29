'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  blockCustomer,
  dismissSupportComplaint,
  getCustomer,
  getCustomerMessages,
  getSupportComplaints,
  resolveSupportComplaint,
  sendCustomerMessage,
  unblockCustomer,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import type { AdminCustomer, ComplaintStatus, CustomerComplaint, CustomerMessage } from '@/lib/types';

type Tab = 'complaints' | 'messages';
const TABS: { id: Tab; label: string }[] = [
  { id: 'complaints', label: "Shikoyatlar" },
  { id: 'messages', label: 'Xabar yuborish' },
];

const STATUS_LABEL: Record<ComplaintStatus, string> = {
  OPEN: 'Ochiq',
  RESOLVED: 'Hal qilindi',
  DISMISSED: 'Rad etildi',
};
const STATUS_COLOR: Record<ComplaintStatus, string> = {
  OPEN: 'var(--red, #ef4444)',
  RESOLVED: 'var(--green)',
  DISMISSED: '#64748b',
};
const STATUS_FILTERS: { id: ComplaintStatus | 'all'; label: string }[] = [
  { id: 'all', label: 'Barchasi' },
  { id: 'OPEN', label: 'Ochiq' },
  { id: 'RESOLVED', label: 'Hal qilindi' },
  { id: 'DISMISSED', label: 'Rad etildi' },
];
const TYPE_LABEL: Record<string, string> = { FOOD: 'Ovqat', TAXI: 'Taksi', PARCEL: 'Dostavka' };

function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString('ru-RU');
}

export default function CustomerComplaintsPage() {
  const [tab, setTab] = useState<Tab>('complaints');

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">E&apos;tirozli mijozlar</h1>
          <p className="page-subtitle">
            Haydovchilar AI yordamchi orqali bildirgan shikoyatlar va mijozlarga push xabar yuborish
          </p>
        </div>
      </div>

      <div className="section-tabs">
        {TABS.map((t) => (
          <button
            key={t.id}
            className={`section-tab ${tab === t.id ? 'active' : ''}`}
            onClick={() => setTab(t.id)}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'complaints' && <ComplaintsTab />}
      {tab === 'messages' && <MessagesTab />}
    </div>
  );
}

function ComplaintsTab() {
  const toast = useToast();
  const dialog = useDialog();

  const [items, setItems] = useState<CustomerComplaint[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<ComplaintStatus | 'all'>('OPEN');
  const [openId, setOpenId] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  const [customers, setCustomers] = useState<Map<string, AdminCustomer>>(new Map());
  const [customerLoading, setCustomerLoading] = useState<string | null>(null);

  const [blockPanelFor, setBlockPanelFor] = useState<string | null>(null);
  const [blockReason, setBlockReason] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setItems(await getSupportComplaints(statusFilter === 'all' ? undefined : statusFilter));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [statusFilter, toast]);

  useEffect(() => { load(); }, [load]);

  async function toggleOpen(complaint: CustomerComplaint) {
    const next = openId === complaint.id ? null : complaint.id;
    setOpenId(next);
    if (next && complaint.customerId && !customers.has(complaint.customerId)) {
      setCustomerLoading(complaint.customerId);
      try {
        const c = await getCustomer(complaint.customerId);
        setCustomers((prev) => new Map(prev).set(c.id, c));
      } catch {
        /* jim — badge ko'rsatilmaydi */
      } finally {
        setCustomerLoading(null);
      }
    }
  }

  async function doResolve(id: string) {
    setBusy(id);
    try {
      await resolveSupportComplaint(id);
      setItems((prev) => prev.map((c) => (c.id === id ? { ...c, status: 'RESOLVED' } : c)));
      toast('Shikoyat hal qilindi deb belgilandi', 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(null);
    }
  }

  async function doDismiss(id: string) {
    const ok = await dialog.confirm("Bu shikoyat asossiz deb rad etilsinmi?", { title: 'Rad etish' });
    if (!ok) return;
    setBusy(id);
    try {
      await dismissSupportComplaint(id);
      setItems((prev) => prev.map((c) => (c.id === id ? { ...c, status: 'DISMISSED' } : c)));
      toast('Shikoyat rad etildi', 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(null);
    }
  }

  async function doWarn(customerId: string, customerName: string | null) {
    const text = await dialog.prompt('Ogohlantirish matnini yozing:', {
      title: `${customerName ?? 'Mijoz'}ga ogohlantirish`,
      placeholder: 'Diqqat: xatti-harakatingiz haqida shikoyat tushdi...',
    });
    if (!text?.trim()) return;
    setBusy(customerId);
    try {
      await sendCustomerMessage({ customerId, title: 'Ogohlantirish', body: text.trim() });
      toast(`Ogohlantirish ${customerName ?? 'mijoz'}ga yuborildi`, 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(null);
    }
  }

  async function submitBlock(customerId: string) {
    const reason = blockReason.trim();
    if (reason.length < 3) {
      toast('Sabab kamida 3 ta belgidan iborat bo‘lishi kerak', 'error');
      return;
    }
    setBusy(customerId);
    try {
      const updated = await blockCustomer(customerId, reason);
      setCustomers((prev) => new Map(prev).set(updated.id, updated));
      setBlockPanelFor(null);
      toast('Mijoz bloklandi', 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(null);
    }
  }

  async function doUnblock(customerId: string) {
    const ok = await dialog.confirm('Mijoz blokdan chiqariladi. Davom etasizmi?', { title: 'Blokdan chiqarish' });
    if (!ok) return;
    setBusy(customerId);
    try {
      const updated = await unblockCustomer(customerId);
      setCustomers((prev) => new Map(prev).set(updated.id, updated));
      toast('Mijoz blokdan chiqarildi', 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(null);
    }
  }

  return (
    <div>
      <div className="filters">
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.id}
            className={`chip ${statusFilter === f.id ? 'active' : ''}`}
            onClick={() => setStatusFilter(f.id)}
          >
            {f.label}
          </button>
        ))}
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
      ) : items.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">✅</div>
            <div className="empty-title">Shikoyat topilmadi</div>
            <div className="empty-desc">Bu bo&apos;limda hozircha yozuv yo&apos;q</div>
          </div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {items.map((c) => {
            const customer = c.customerId ? customers.get(c.customerId) : undefined;
            const blocked = !!customer?.isBlocked;
            const isBusy = busy === c.id || (c.customerId != null && busy === c.customerId);
            return (
              <div key={c.id} className="card">
                <div className="card-header" style={{ cursor: 'pointer' }} onClick={() => toggleOpen(c)}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <span style={{ fontSize: 18 }}>🗣️</span>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--text)' }}>
                        {c.driverInfo?.fullName ?? 'Nomaʻlum haydovchi'}
                        <span style={{ color: 'var(--text-muted)', fontWeight: 500 }}> → </span>
                        {c.customerInfo?.fullName ?? c.customerInfo?.phone ?? 'Mijoz aniqlanmadi'}
                      </div>
                      <div style={{ fontSize: 12.5, color: 'var(--text-muted)', marginTop: 2 }}>
                        {c.orderType ? `${TYPE_LABEL[c.orderType] ?? c.orderType} #${c.orderPublicNo}` : 'Buyurtma nomaʻlum'}
                        {' · '}{formatDateTime(c.createdAt)}
                      </div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                    <span className="badge" style={{ background: STATUS_COLOR[c.status], fontSize: 11.5 }}>
                      {STATUS_LABEL[c.status]}
                    </span>
                    <span style={{ color: 'var(--text-muted)', transform: openId === c.id ? 'rotate(90deg)' : 'none', transition: 'transform 150ms' }}>›</span>
                  </div>
                </div>

                {openId === c.id && (
                  <div className="card-body" style={{ borderTop: '1px solid var(--border)' }}>
                    <div style={{ fontSize: 13.5, color: 'var(--text-2)', marginBottom: 14, lineHeight: 1.6 }}>
                      &ldquo;{c.summary}&rdquo;
                    </div>

                    <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', marginBottom: 14, fontSize: 12.5, color: 'var(--text-muted)' }}>
                      <span>📞 Haydovchi: {c.driverInfo?.phone ?? '—'}</span>
                      <span>📞 Mijoz: {c.customerInfo?.phone ?? '—'}</span>
                    </div>

                    {!c.customerId ? (
                      <div className="info-block amber" style={{ fontSize: 12.5 }}>
                        Mijoz avtomatik aniqlanmadi (buyurtma raqami noto&apos;g&apos;ri yoki topilmadi) — ogohlantirish/bloklash imkonsiz.
                      </div>
                    ) : customerLoading === c.customerId ? (
                      <div className="sk sk-line" style={{ width: '40%', height: 13 }} />
                    ) : (
                      <>
                        {blocked && customer && (
                          <div className="info-block red" style={{ marginBottom: 10, fontSize: 12.5 }}>
                            🚫 Mijoz bloklangan.{customer.blockedReason ? ` Sabab: ${customer.blockedReason}` : ''}
                          </div>
                        )}
                        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 10 }}>
                          <button className="btn ghost btn-sm" disabled={isBusy} onClick={() => doWarn(c.customerId!, c.customerInfo?.fullName ?? null)}>
                            ⚠️ Ogohlantirish
                          </button>
                          {blocked ? (
                            <button className="btn ghost btn-sm" disabled={isBusy} style={{ color: 'var(--green)', borderColor: 'var(--green)' }} onClick={() => doUnblock(c.customerId!)}>
                              ✅ Blokdan chiqarish
                            </button>
                          ) : (
                            <button
                              className="btn ghost btn-sm"
                              disabled={isBusy}
                              style={{ color: 'var(--red)', borderColor: 'var(--red)' }}
                              onClick={() => { setBlockPanelFor(c.customerId!); setBlockReason(''); }}
                            >
                              🚫 Bloklash
                            </button>
                          )}
                        </div>

                        {blockPanelFor === c.customerId && (
                          <div style={{ marginBottom: 10, padding: 12, background: 'var(--surface-2)', border: '1px solid var(--border)', borderRadius: 8 }}>
                            <label>Bloklash sababi *</label>
                            <textarea
                              value={blockReason}
                              onChange={(e) => setBlockReason(e.target.value)}
                              placeholder="Masalan: haydovchiga qo'pol muomala + to'lovni to'lamagan"
                              rows={2}
                              maxLength={500}
                              style={{ resize: 'vertical', width: '100%', marginBottom: 10 }}
                            />
                            <div style={{ display: 'flex', gap: 8 }}>
                              <button className="btn red btn-sm" disabled={isBusy} onClick={() => submitBlock(c.customerId!)}>
                                {isBusy ? 'Bloklanmoqda…' : '🚫 Bloklash'}
                              </button>
                              <button className="btn ghost btn-sm" onClick={() => setBlockPanelFor(null)}>Bekor qilish</button>
                            </div>
                          </div>
                        )}
                      </>
                    )}

                    {c.status === 'OPEN' && (
                      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 4 }}>
                        <button className="btn green btn-sm" disabled={isBusy} onClick={() => doResolve(c.id)}>
                          ✅ Hal qilindi deb belgilash
                        </button>
                        <button className="btn ghost btn-sm" disabled={isBusy} onClick={() => doDismiss(c.id)}>
                          ✕ Rad etish (asossiz)
                        </button>
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

/* ============ Xabar yuborish (barcha mijozlarga push) ============ */

function MessagesTab() {
  const toast = useToast();
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [busy, setBusy] = useState(false);
  const [sent, setSent] = useState<CustomerMessage[]>([]);

  const loadSent = useCallback(async () => {
    try {
      setSent(await getCustomerMessages());
    } catch {
      /* tarix ixtiyoriy — jim */
    }
  }, []);

  useEffect(() => { loadSent(); }, [loadSent]);

  async function sendBroadcast() {
    if (!body.trim()) {
      toast('Xabar matnini kiriting', 'error');
      return;
    }
    setBusy(true);
    try {
      await sendCustomerMessage({ title: title.trim() || undefined, body: body.trim() });
      setTitle('');
      setBody('');
      toast('Xabar barcha mijozlarga yuborildi', 'success');
      await loadSent();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <div className="card" style={{ marginBottom: 16 }}>
        <div className="card-header">
          <span className="card-title">📣 Barcha mijozlarga xabar</span>
          <span style={{ fontSize: 12.5, color: 'var(--text-muted)' }}>
            Mijoz ilovasiga push bildirishnoma sifatida boradi
          </span>
        </div>
        <div className="card-body">
          <div style={{ display: 'grid', gap: 12, maxWidth: 640 }}>
            <div>
              <label>Sarlavha (ixtiyoriy)</label>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Masalan: E'lon"
                maxLength={120}
              />
            </div>
            <div>
              <label>Xabar matni *</label>
              <textarea
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Xabar matnini yozing…"
                rows={3}
                maxLength={2000}
                style={{ resize: 'vertical' }}
              />
            </div>
            <div>
              <button className="btn" disabled={busy || !body.trim()} onClick={sendBroadcast}>
                {busy ? 'Yuborilmoqda…' : '📣 Hammaga yuborish'}
              </button>
            </div>
          </div>
        </div>
      </div>

      {sent.length > 0 && (
        <div className="card">
          <div className="card-header">
            <span className="card-title">Yuborilganlar tarixi</span>
          </div>
          <div className="card-body">
            <div style={{ display: 'grid', gap: 6 }}>
              {sent.map((m) => (
                <div
                  key={m.id}
                  style={{
                    display: 'flex',
                    gap: 10,
                    alignItems: 'flex-start',
                    padding: '9px 12px',
                    background: 'var(--surface-2)',
                    borderRadius: 10,
                    fontSize: 13,
                  }}
                >
                  <span
                    className="badge"
                    style={{
                      background: m.customerId ? 'var(--primary)' : 'var(--green)',
                      fontSize: 10.5,
                      flexShrink: 0,
                      marginTop: 1,
                    }}
                  >
                    {m.customerId ? 'Shaxsiy' : 'Hammaga'}
                  </span>
                  <div style={{ flex: 1 }}>
                    {m.title && <div style={{ fontWeight: 700, marginBottom: 2 }}>{m.title}</div>}
                    <div style={{ color: 'var(--text-2)' }}>{m.body}</div>
                    <div style={{ fontSize: 11.5, color: 'var(--text-muted)', marginTop: 3 }}>
                      {formatDateTime(m.createdAt)}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
