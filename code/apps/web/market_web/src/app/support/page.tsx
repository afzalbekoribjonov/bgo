'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { getSupportMessages, sendSupportMessage } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useAuthState } from '@/lib/auth-context';
import Topbar from '@/components/topbar';
import type { SupportMessage } from '@/lib/types';

export default function SupportPage() {
  const toast = useToast();
  const { ready, authed } = useAuthState();
  const [messages, setMessages] = useState<SupportMessage[]>([]);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  const load = useCallback(async () => {
    try {
      setMessages(await getSupportMessages());
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }, [toast]);

  useEffect(() => {
    if (ready && authed) {
      load();
      const t = setInterval(load, 6000);
      return () => clearInterval(t);
    }
  }, [ready, authed, load]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages.length]);

  async function send() {
    if (!text.trim()) return;
    setSending(true);
    try {
      const m = await sendSupportMessage(text.trim());
      setMessages((arr) => [...arr, m]);
      setText('');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setSending(false);
    }
  }

  return (
    <>
      <Topbar title="💬 Market Support" />
      <div className="content" style={{ paddingBottom: authed ? 90 : 20 }}>
        {!ready ? null : !authed ? (
          <div className="empty">
            <div className="empty-icon">🔒</div>
            <div className="empty-title">Support bilan yozishish uchun ilovadan oching</div>
          </div>
        ) : messages.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">💬</div>
            <div className="empty-title">Savolingiz bormi?</div>
            <div className="empty-desc">Bizga yozing — imkon qadar tez javob beramiz</div>
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
      {authed && (
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
      )}
    </>
  );
}
