'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { Alarm } from '@/lib/alarm';
import {
  formatSom,
  getKitchenOrders,
  getOrderMessages,
  orderAction,
  sendOrderMessage,
} from '@/lib/api';
import type { Order, OrderMessage } from '@/lib/types';
import { useRestaurant } from '../restaurant-provider';

function phase(o: Order): {
  label: string;
  color: string;
  bgColor: string;
  isNew: boolean;
} {
  if (o.status === 'PENDING' && !o.kitchenAcceptedAt)
    return {
      label: 'Yangi buyurtma',
      color: 'var(--orange)',
      bgColor: 'rgba(240,140,0,0.1)',
      isNew: true,
    };
  if (o.status === 'PENDING' && o.kitchenAcceptedAt && !o.driverId)
    return {
      label: 'Kuryer qidirilmoqda',
      color: 'var(--blue)',
      bgColor: 'rgba(25,113,194,0.08)',
      isNew: false,
    };
  if (o.status === 'ACCEPTED')
    return {
      label: 'Tasdiqlandi',
      color: 'var(--blue)',
      bgColor: 'rgba(25,113,194,0.08)',
      isNew: false,
    };
  if (o.status === 'PREPARING')
    return {
      label: 'Tayyorlanmoqda',
      color: 'var(--orange)',
      bgColor: 'rgba(240,140,0,0.1)',
      isNew: false,
    };
  if (o.status === 'READY')
    return {
      label: 'Tayyor · kuryer oldida',
      color: 'var(--green)',
      bgColor: 'rgba(31,157,85,0.1)',
      isNew: false,
    };
  if (['ASSIGNED', 'IN_PROGRESS', 'PICKED_UP'].includes(o.status))
    return {
      label: "Kuryerda · yoʼlda",
      color: 'var(--green)',
      bgColor: 'rgba(31,157,85,0.1)',
      isNew: false,
    };
  if (['DELIVERED', 'COMPLETED'].includes(o.status))
    return {
      label: 'Yetkazildi',
      color: 'var(--green)',
      bgColor: 'rgba(31,157,85,0.1)',
      isNew: false,
    };
  return {
    label: 'Bekor qilindi',
    color: 'var(--red)',
    bgColor: 'rgba(224,49,49,0.08)',
    isNew: false,
  };
}

function timeAgo(iso: string): string {
  const sec = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (sec < 60) return `${sec}s oldin`;
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min} daqiqa oldin`;
  const hr = Math.floor(min / 60);
  return `${hr} soat oldin`;
}

const ACTIVE = [
  'PENDING',
  'ACCEPTED',
  'PREPARING',
  'READY',
  'ASSIGNED',
  'IN_PROGRESS',
  'PICKED_UP',
];

function StatusBanner() {
  const { restaurant, busy, toggle } = useRestaurant();
  if (!restaurant) return null;
  const open = restaurant.isOpen;
  return (
    <div
      className="status-banner"
      style={{
        background: open ? 'rgba(31,157,85,0.07)' : 'rgba(224,49,49,0.05)',
        borderColor: open ? 'rgba(31,157,85,0.22)' : 'rgba(224,49,49,0.18)',
      }}
    >
      <div className="status-banner-left">
        <div
          className="status-dot-xl"
          style={{ background: open ? 'var(--green)' : 'var(--red)' }}
        />
        <div>
          <div
            className="status-banner-title"
            style={{ color: open ? 'var(--green)' : 'var(--red)' }}
          >
            {open ? 'OCHIQ' : 'YOPIQ'}
          </div>
          <div className="status-banner-sub">
            {open
              ? 'Buyurtmalar qabul qilinmoqda'
              : 'Buyurtmalar kelmaydi'}
          </div>
        </div>
      </div>

      <button
        className={`status-toggle-btn ${open ? 'open' : 'closed'}`}
        onClick={toggle}
        disabled={busy}
      >
        <span className="status-toggle-track">
          <span className="status-toggle-knob" />
        </span>
        <span>{open ? 'Yopish' : 'Ochish'}</span>
      </button>
    </div>
  );
}

export default function OrdersPage({ params }: { params: { id: string } }) {
  const rid = params.id;
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [chatId, setChatId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const alarmRef = useRef<Alarm | null>(null);
  const lastNewRef = useRef(0);
  const silencedRef = useRef(false);

  const load = useCallback(async () => {
    try {
      const all = await getKitchenOrders(rid);
      setOrders(all.filter((o) => ACTIVE.includes(o.status)));
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, [rid]);

  useEffect(() => {
    alarmRef.current = new Alarm();
    return () => {
      alarmRef.current?.stop();
      alarmRef.current = null;
    };
  }, []);

  useEffect(() => {
    load();
    const timer = setInterval(load, 4000);
    return () => clearInterval(timer);
  }, [load]);

  useEffect(() => {
    const alarm = alarmRef.current;
    if (!alarm) return;
    const news = orders.filter((o) => phase(o).isNew).length;
    if (news === 0) {
      silencedRef.current = false;
      lastNewRef.current = 0;
      alarm.stop();
      return;
    }
    if (news > lastNewRef.current) silencedRef.current = false;
    lastNewRef.current = news;
    if (silencedRef.current) alarm.stop();
    else alarm.start();
  }, [orders]);

  async function act(
    id: string,
    action: 'accept' | 'preparing' | 'ready' | 'reject',
  ) {
    if (action === 'accept' || action === 'reject') {
      silencedRef.current = true;
      alarmRef.current?.stop();
    }
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
    <div className="container" style={{ paddingBottom: 24 }}>
      <StatusBanner />

      <div className="row" style={{ marginBottom: 14, marginTop: 4 }}>
        <h2 className="big">Faol buyurtmalar</h2>
        <span className="time-chip">jonli · har 4s</span>
      </div>

      {error && (
        <div
          style={{
            background: 'rgba(224,49,49,0.07)',
            border: '1px solid rgba(224,49,49,0.3)',
            borderRadius: 12,
            padding: '12px 14px',
            marginBottom: 12,
          }}
        >
          <div style={{ color: 'var(--red)', fontWeight: 700, fontSize: 14 }}>
            ⚠ {error}
          </div>
          <button
            className="btn ghost sm"
            style={{ marginTop: 8 }}
            onClick={load}
          >
            Qayta urinish
          </button>
        </div>
      )}

      {loading && (
        <p className="muted" style={{ textAlign: 'center', padding: '48px 0' }}>
          Yuklanmoqda…
        </p>
      )}

      {!loading && orders.length === 0 && !error && (
        <div className="empty">
          <div style={{ fontSize: 38, marginBottom: 8 }}>✅</div>
          <div
            style={{ fontWeight: 700, fontSize: 16, marginBottom: 4 }}
          >
            Barcha buyurtmalar bajarildi
          </div>
          <div>Yangi buyurtma kelganda ovoz beradi</div>
        </div>
      )}

      {orders.map((o) => {
        const p = phase(o);
        const isBusy = busy === o.id;

        return (
          <div className={`card ${p.isNew ? 'new' : ''}`} key={o.id}>
            {/* Sarlavha: raqam + vaqt */}
            <div className="row" style={{ marginBottom: 6 }}>
              <div>
                <div className="order-no">#{o.publicNo}</div>
                {o.createdAt && (
                  <div className="time-chip">{timeAgo(o.createdAt)}</div>
                )}
              </div>
              {p.isNew && (
                <span
                  style={{
                    fontSize: 11,
                    fontWeight: 800,
                    color: 'var(--orange)',
                    background: 'rgba(240,140,0,0.12)',
                    padding: '3px 10px',
                    borderRadius: 20,
                    letterSpacing: 0.5,
                  }}
                >
                  YANGI
                </span>
              )}
            </div>

            {/* Holat konteyneri */}
            <div
              className="status-box"
              style={{ color: p.color, background: p.bgColor }}
            >
              <span className="status-dot" style={{ background: p.color }} />
              <span>{p.label}</span>
            </div>

            {/* Manzil */}
            <div className="order-addr">
              <span>📍</span>
              <span>{o.address.text}</span>
            </div>

            {/* Taomlar */}
            <div className="items">
              {o.items.map((it, i) => (
                <div className="item-row" key={i}>
                  <span>
                    {it.nameSnapshot} × <b>{it.qty}</b>
                  </span>
                  <span className="muted">{formatSom(it.lineTotal)}</span>
                </div>
              ))}
            </div>

            {/* Jami */}
            <div className="row" style={{ marginBottom: 12 }}>
              <span className="muted" style={{ fontSize: 14 }}>
                {o.items.length} ta taom
              </span>
              <span className="order-total">{formatSom(o.total)}</span>
            </div>

            {/* Harakatlar */}
            <div className="btn-group">
              {o.status === 'PENDING' && !o.kitchenAcceptedAt && (
                <>
                  <button
                    className="btn green"
                    disabled={isBusy}
                    onClick={() => act(o.id, 'accept')}
                  >
                    ✓ Qabul qilish
                  </button>
                  <button
                    className="btn red"
                    disabled={isBusy}
                    onClick={() => act(o.id, 'reject')}
                  >
                    ✕ Rad etish
                  </button>
                </>
              )}
              {o.status === 'PENDING' &&
                o.kitchenAcceptedAt &&
                !o.driverId && (
                  <span className="wait-chip">⏳ Kuryer qidirilmoqda…</span>
                )}
              {o.status === 'ACCEPTED' && (
                <button
                  className="btn orange"
                  disabled={isBusy}
                  onClick={() => act(o.id, 'preparing')}
                >
                  🍳 Tayyorlashni boshlash
                </button>
              )}
              {o.status === 'PREPARING' && (
                <button
                  className="btn green"
                  disabled={isBusy}
                  onClick={() => act(o.id, 'ready')}
                >
                  ✓ Tayyor — kuryer olishi mumkin
                </button>
              )}
              {o.status === 'READY' && (
                <span className="wait-chip">📦 Kuryerga topshiring</span>
              )}
              {o.driverId &&
                !['DELIVERED', 'COMPLETED'].includes(o.status) && (
                  <button
                    className="btn ghost"
                    onClick={() => setChatId(o.id)}
                  >
                    💬 Kuryer bilan gaplash
                  </button>
                )}
            </div>
          </div>
        );
      })}

      {chatId && (
        <ChatSheet orderId={chatId} onClose={() => setChatId(null)} />
      )}
    </div>
  );
}

function ChatSheet({
  orderId,
  onClose,
}: {
  orderId: string;
  onClose: () => void;
}) {
  const [messages, setMessages] = useState<OrderMessage[]>([]);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const bodyRef = useRef<HTMLDivElement | null>(null);

  const load = useCallback(async () => {
    try {
      setMessages(await getOrderMessages(orderId));
    } catch {
      /* ignore */
    }
  }, [orderId]);

  useEffect(() => {
    load();
    const t = setInterval(load, 3000);
    return () => clearInterval(t);
  }, [load]);

  useEffect(() => {
    bodyRef.current?.scrollTo(0, bodyRef.current.scrollHeight);
  }, [messages]);

  async function send() {
    const t = text.trim();
    if (!t || sending) return;
    setSending(true);
    try {
      await sendOrderMessage(orderId, t);
      setText('');
      await load();
    } catch {
      /* ignore */
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="chat-overlay" onClick={onClose}>
      <div className="chat-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="chat-head">
          <span>Kuryer bilan suhbat</span>
          <button className="btn ghost sm" onClick={onClose}>
            ✕ Yopish
          </button>
        </div>
        <div className="chat-body" ref={bodyRef}>
          {messages.length === 0 && (
            <p
              className="muted"
              style={{ textAlign: 'center', marginTop: 24 }}
            >
              Hali xabar yo&apos;q — yozing, kuryer ko&apos;radi
            </p>
          )}
          {messages.map((m) => (
            <div
              key={m.id}
              className={`bubble ${m.senderRole === 'kitchen' ? 'me' : 'them'}`}
            >
              {m.text}
            </div>
          ))}
        </div>
        <div className="chat-input">
          <input
            className="field"
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && send()}
            placeholder="Xabar yozing…"
            style={{ margin: 0 }}
          />
          <button
            className="btn primary"
            disabled={sending || !text.trim()}
            onClick={send}
          >
            ➤
          </button>
        </div>
      </div>
    </div>
  );
}
