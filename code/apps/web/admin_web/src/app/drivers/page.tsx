'use client';

import Link from 'next/link';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  createDriver,
  formatSom,
  getDriverMessages,
  getDrivers,
  sendDriverMessage,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import type { AdminDriver, AdminDriverMessage } from '@/lib/types';

/** Bir sahifada ko'rsatiladigan haydovchilar soni — flot kattalashganda
 * sahifa minglab qatorni birdan render qilib og'irlashib ketmasin. */
const PAGE_SIZE = 40;

export default function DriversPage() {
  const toast = useToast();
  const [drivers, setDrivers] = useState<AdminDriver[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<'all' | 'online' | 'offline' | 'inactive'>('all');
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE);
  const [showCreate, setShowCreate] = useState(false);

  // Create form
  const [phone, setPhone] = useState('');
  const [fullName, setFullName] = useState('');
  const [carName, setCarName] = useState('');
  const [plateNumber, setPlateNumber] = useState('');
  const [formErr, setFormErr] = useState('');

  // Xabar yuborish (hammaga) + tarix
  const [showMsg, setShowMsg] = useState(false);
  const [msgTitle, setMsgTitle] = useState('');
  const [msgBody, setMsgBody] = useState('');
  const [msgBusy, setMsgBusy] = useState(false);
  const [sentMsgs, setSentMsgs] = useState<AdminDriverMessage[]>([]);

  const loadMessages = useCallback(async () => {
    try {
      setSentMsgs(await getDriverMessages());
    } catch {
      /* tarix ixtiyoriy — jim */
    }
  }, []);

  async function sendBroadcast() {
    if (!msgBody.trim()) {
      toast('Xabar matnini kiriting', 'error');
      return;
    }
    setMsgBusy(true);
    try {
      await sendDriverMessage({
        title: msgTitle.trim() || undefined,
        body: msgBody.trim(),
      });
      setMsgTitle('');
      setMsgBody('');
      toast('Xabar barcha haydovchilarga yuborildi', 'success');
      await loadMessages();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setMsgBusy(false);
    }
  }

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setDrivers(await getDrivers());
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  async function add() {
    setFormErr('');
    if (!phone.trim() || !fullName.trim()) {
      setFormErr("Telefon va to'liq ism majburiy");
      return;
    }
    if (!/^\+998\d{9}$/.test(phone.trim())) {
      setFormErr("+998XXXXXXXXX formatida kiriting");
      return;
    }
    setBusy(true);
    try {
      await createDriver({
        phone: phone.trim(),
        fullName: fullName.trim(),
        carName: carName.trim() || undefined,
        plateNumber: plateNumber.trim() || undefined,
      });
      setPhone(''); setFullName(''); setCarName(''); setPlateNumber(''); setFormErr('');
      setShowCreate(false);
      toast("Haydovchi qo'shildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(false);
    }
  }

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return drivers.filter((d) => {
      const matchFilter =
        filter === 'all' ||
        (filter === 'online' && d.isOnline && d.isActive) ||
        (filter === 'offline' && !d.isOnline && d.isActive) ||
        (filter === 'inactive' && !d.isActive);
      const matchQ =
        q === '' ||
        d.fullName.toLowerCase().includes(q) ||
        d.phone.includes(q) ||
        (d.plateNumber ?? '').toLowerCase().includes(q);
      return matchFilter && matchQ;
    });
  }, [drivers, query, filter]);

  // Qidiruv/filtr o'zgarsa ko'rinadigan sahifa boshidan boshlansin.
  useEffect(() => setVisibleCount(PAGE_SIZE), [query, filter]);

  const visible = filtered.slice(0, visibleCount);

  const stats = useMemo(() => ({
    total: drivers.length,
    online: drivers.filter((d) => d.isOnline && d.isActive).length,
    active: drivers.filter((d) => d.isActive).length,
  }), [drivers]);

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Haydovchilar</h1>
          <p className="page-subtitle">{drivers.length} ta haydovchi</p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button
            className="btn ghost"
            onClick={() => {
              setShowMsg((v) => {
                if (!v) loadMessages();
                return !v;
              });
              setShowCreate(false);
            }}
          >
            {showMsg ? '✕ Yopish' : '📣 Xabar yuborish'}
          </button>
          <button
            className="btn"
            onClick={() => {
              setShowCreate((v) => !v);
              setShowMsg(false);
            }}
          >
            {showCreate ? '✕ Yopish' : '+ Yangi haydovchi'}
          </button>
        </div>
      </div>

      {/* Hammaga xabar yuborish + tarix */}
      {showMsg && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">📣 Barcha haydovchilarga xabar</span>
            <span style={{ fontSize: 12.5, color: 'var(--text-muted)' }}>
              Haydovchi ilovasidagi qo&apos;ng&apos;iroqchaga boradi (javob yozolmaydi)
            </span>
          </div>
          <div className="card-body">
            <div style={{ display: 'grid', gap: 12, maxWidth: 640 }}>
              <div>
                <label>Sarlavha (ixtiyoriy)</label>
                <input
                  value={msgTitle}
                  onChange={(e) => setMsgTitle(e.target.value)}
                  placeholder="Masalan: E'lon"
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
                <button className="btn" disabled={msgBusy || !msgBody.trim()} onClick={sendBroadcast}>
                  {msgBusy ? 'Yuborilmoqda…' : '📣 Hammaga yuborish'}
                </button>
              </div>
            </div>

            {sentMsgs.length > 0 && (
              <div style={{ marginTop: 18 }}>
                <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.5, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 8 }}>
                  Yuborilganlar tarixi
                </div>
                <div style={{ display: 'grid', gap: 6, maxHeight: 260, overflowY: 'auto' }}>
                  {sentMsgs.map((m) => (
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
                          background: m.driverUserId ? 'var(--primary)' : 'var(--green)',
                          fontSize: 10.5,
                          flexShrink: 0,
                          marginTop: 1,
                        }}
                      >
                        {m.driverUserId ? 'Shaxsiy' : 'Hammaga'}
                      </span>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        {m.title && <div style={{ fontWeight: 700, marginBottom: 1 }}>{m.title}</div>}
                        <div style={{ color: 'var(--text)', overflow: 'hidden', textOverflow: 'ellipsis' }}>{m.body}</div>
                      </div>
                      <span style={{ color: 'var(--text-muted)', fontSize: 11.5, flexShrink: 0 }}>
                        {new Date(m.createdAt).toLocaleString('uz-UZ', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="stats">
        <div className="stat-card">
          <div className="stat-label">🚗 Jami</div>
          <div className="stat-value">{stats.total}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">🟢 Online</div>
          <div className="stat-value text-green">{stats.online}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">✅ Faol</div>
          <div className="stat-value">{stats.active}</div>
        </div>
      </div>

      {/* Create form */}
      {showCreate && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">Yangi haydovchi ro'yxatdan o'tkazish</span>
          </div>
          <div className="card-body">
            <div className="form-grid form-grid-auto" style={{ marginBottom: 14 }}>
              <div>
                <label>Telefon *</label>
                <input
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+998901234567"
                  inputMode="tel"
                />
              </div>
              <div>
                <label>To'liq ismi *</label>
                <input
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Firstname Lastname"
                />
              </div>
              <div>
                <label>Avtomobil</label>
                <input
                  value={carName}
                  onChange={(e) => setCarName(e.target.value)}
                  placeholder="Chevrolet Nexia 3"
                />
              </div>
              <div>
                <label>Davlat raqami</label>
                <input
                  value={plateNumber}
                  onChange={(e) => setPlateNumber(e.target.value.toUpperCase())}
                  placeholder="30 A 123 AB"
                />
              </div>
            </div>
            {formErr && (
              <div className="err-block" style={{ marginBottom: 12, maxWidth: 480 }}>
                {formErr}
              </div>
            )}
            <button className="btn" disabled={busy} onClick={add}>
              {busy ? "Qo'shilyapti…" : "Qo'shish"}
            </button>
          </div>
        </div>
      )}

      {/* Filters */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap', alignItems: 'flex-end' }}>
        <div style={{ flex: 1, minWidth: 200 }}>
          <label>Qidiruv</label>
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Ism, telefon yoki davlat raqami…"
          />
        </div>
        <div className="filters" style={{ marginBottom: 0, paddingTop: 16 }}>
          {(['all', 'online', 'offline', 'inactive'] as const).map((f) => (
            <button
              key={f}
              className={`chip ${filter === f ? 'active' : ''}`}
              onClick={() => setFilter(f)}
            >
              {f === 'all' ? 'Barchasi' : f === 'online' ? '🟢 Online' : f === 'offline' ? '⭕ Offline' : '🔴 Nofaol'}
            </button>
          ))}
        </div>
      </div>

      {/* List */}
      {loading ? (
        <div>
          {[...Array(6)].map((_, i) => (
            <div key={i} className="card" style={{ marginBottom: 8, padding: '16px 20px', display: 'flex', gap: 12, alignItems: 'center' }}>
              <div className="sk" style={{ width: 40, height: 40, borderRadius: '50%', flexShrink: 0 }} />
              <div style={{ flex: 1 }}>
                <div className="sk sk-line" style={{ width: '35%', marginBottom: 8, height: 15 }} />
                <div className="sk sk-line sk-line-md" style={{ height: 12 }} />
              </div>
              <div className="sk sk-line" style={{ width: 80, height: 24, borderRadius: 20 }} />
            </div>
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">🚗</div>
            <div className="empty-title">Haydovchi topilmadi</div>
            <div className="empty-desc">Qidiruvni yoki filtrlni o'zgartiring</div>
          </div>
        </div>
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {visible.map((d) => (
            <Link key={d.id} href={`/drivers/${d.id}`} className="list-item card-link">
              {/* Avatar */}
              <div
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: '50%',
                  background: 'var(--primary)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#fff',
                  fontWeight: 700,
                  fontSize: 16,
                  flexShrink: 0,
                  position: 'relative',
                }}
              >
                {d.fullName.charAt(0).toUpperCase()}
                {d.isActive && (
                  <span
                    style={{
                      position: 'absolute',
                      bottom: 1,
                      right: 1,
                      width: 10,
                      height: 10,
                      borderRadius: '50%',
                      background: d.isOnline ? 'var(--green)' : '#94a3b8',
                      border: '2px solid var(--surface)',
                      boxShadow: d.isOnline ? '0 0 5px var(--green)' : 'none',
                    }}
                  />
                )}
              </div>

              {/* Info */}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--text)', marginBottom: 2 }}>
                  {d.fullName}
                </div>
                <div style={{ fontSize: 12.5, color: 'var(--text-muted)', display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  <span>📞 {d.phone}</span>
                  {d.carName && <span>🚗 {d.carName}</span>}
                  {d.plateNumber && <span>🔢 {d.plateNumber}</span>}
                </div>
              </div>

              {/* Balance */}
              <div style={{ textAlign: 'right', flexShrink: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 700, color: d.balance < 0 ? 'var(--red)' : 'var(--text)' }}>
                  {formatSom(d.balance)}
                </div>
                <div style={{ fontSize: 11.5, color: 'var(--text-muted)' }}>balans</div>
              </div>

              {/* Status */}
              <span
                className="badge"
                style={{
                  background: !d.isActive ? 'var(--red)' : d.isOnline ? 'var(--green)' : '#64748b',
                  fontSize: 11.5,
                  flexShrink: 0,
                }}
              >
                {!d.isActive ? 'Nofaol' : d.isOnline ? 'Online' : 'Offline'}
              </span>

              <span style={{ color: 'var(--text-muted)' }}>›</span>
            </Link>
          ))}
        </div>
      )}

      {filtered.length > visibleCount && (
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <button className="btn ghost" onClick={() => setVisibleCount((v) => v + PAGE_SIZE)}>
            Yana ko&apos;rsatish ({filtered.length - visibleCount} ta qoldi)
          </button>
        </div>
      )}
    </div>
  );
}
