'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useParams, useRouter, useSearchParams } from 'next/navigation';
import { getChatMessages, getSeller, sendChatMessage } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useAuthState } from '@/lib/auth-context';
import type { ChatMessage } from '@/lib/types';

export default function ChatConversationPage() {
  const { sellerId } = useParams<{ sellerId: string }>();
  const router = useRouter();
  const searchParams = useSearchParams();
  const toast = useToast();
  const { ready, authed } = useAuthState();
  const [sellerName, setSellerName] = useState('Sotuvchi');
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  // Mahsulot sahifasidan kelgan tayyor xabar (nom + o'lcham) — mijoz
  // tahrirlab yoki shundayligicha yuborishi mumkin.
  const [text, setText] = useState(() => searchParams.get('prefill') ?? '');
  const [sending, setSending] = useState(false);
  const [loading, setLoading] = useState(true);
  const bottomRef = useRef<HTMLDivElement>(null);

  const load = useCallback(async () => {
    try {
      setMessages(await getChatMessages(sellerId));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [sellerId]);

  useEffect(() => {
    if (!ready || !authed) return;
    getSeller(sellerId).then((s) => setSellerName(s.name)).catch(() => {});
    load();
    const t = setInterval(load, 6000);
    return () => clearInterval(t);
  }, [ready, authed, sellerId, load]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages.length]);

  async function send() {
    if (!text.trim()) return;
    setSending(true);
    try {
      const m = await sendChatMessage(sellerId, text.trim());
      setMessages((arr) => [...arr, m]);
      setText('');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setSending(false);
    }
  }

  if (!ready) return null;

  if (!authed) {
    return (
      <>
        <div className="topbar">
          <button className="topbar-back" onClick={() => router.back()}>←</button>
          <span className="topbar-title">Suhbat</span>
        </div>
        <div className="content">
          <div className="empty">
            <div className="empty-icon">🔒</div>
            <div className="empty-title">Yozishish uchun ilovadan oching</div>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <div className="topbar">
        <button className="topbar-back" onClick={() => router.back()}>←</button>
        <span className="topbar-title">{sellerName}</span>
      </div>
      <div className="content" style={{ paddingBottom: 90 }}>
        {loading ? (
          <div className="sk sk-para" />
        ) : messages.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">💬</div>
            <div className="empty-title">Hali xabar yo'q</div>
            <div className="empty-desc">Sotuvchiga birinchi xabarni yozing</div>
          </div>
        ) : (
          <div className="chat-scroll">
            {messages.map((m) => (
              <div key={m.id} className={`bubble ${m.senderRole === 'CUSTOMER' ? 'me' : 'them'}`}>
                {m.text}
              </div>
            ))}
            <div ref={bottomRef} />
          </div>
        )}
      </div>
      <div className="chat-input-row">
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Xabar yozing..."
          onKeyDown={(e) => { if (e.key === 'Enter') send(); }}
        />
        <button className="btn btn-sm" disabled={sending || !text.trim()} onClick={send}>
          Yuborish
        </button>
      </div>
    </>
  );
}
