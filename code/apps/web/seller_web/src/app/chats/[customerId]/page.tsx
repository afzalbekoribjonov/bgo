'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { getChatMessages, sendChatMessage } from '@/lib/api';
import { useToast } from '@/components/toast';
import type { ChatMessage } from '@/lib/types';

export default function ChatConversationPage() {
  const { customerId } = useParams<{ customerId: string }>();
  const router = useRouter();
  const toast = useToast();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [loading, setLoading] = useState(true);
  const bottomRef = useRef<HTMLDivElement>(null);

  const load = useCallback(async () => {
    try {
      setMessages(await getChatMessages(customerId));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [customerId, toast]);

  useEffect(() => {
    load();
    const t = setInterval(load, 6000);
    return () => clearInterval(t);
  }, [load]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages.length]);

  async function send() {
    if (!text.trim()) return;
    setSending(true);
    try {
      const m = await sendChatMessage(customerId, text.trim());
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
      <div className="topbar">
        <button className="topbar-back" onClick={() => router.back()}>←</button>
        <span className="topbar-title">Mijoz bilan suhbat</span>
      </div>
      <div className="content" style={{ paddingBottom: 90 }}>
        {loading ? (
          <div className="sk sk-para" />
        ) : messages.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">💬</div>
            <div className="empty-title">Hali xabar yo'q</div>
          </div>
        ) : (
          <div className="chat-scroll">
            {messages.map((m) => (
              <div key={m.id} className={`bubble ${m.senderRole === 'SELLER' ? 'me' : 'them'}`}>
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
