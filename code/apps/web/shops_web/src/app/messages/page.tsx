'use client';

import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { formatDate, getChatThreads } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useAuthState } from '@/lib/auth-context';
import type { ChatThread } from '@/lib/types';

export default function MessagesPage() {
  const toast = useToast();
  const { ready, authed } = useAuthState();
  const [threads, setThreads] = useState<ChatThread[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try {
      setThreads(await getChatThreads());
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!ready || !authed) { setLoading(false); return; }
    load();
    const t = setInterval(load, 8000);
    return () => clearInterval(t);
  }, [ready, authed, load]);

  return (
    <>
      <div className="topbar">
        <span className="topbar-title">💬 Xabarlarim</span>
      </div>
      <div className="content">
        {!ready ? null : !authed ? (
          <div className="empty">
            <div className="empty-icon">🔒</div>
            <div className="empty-title">Xabarlarni ko'rish uchun ilovadan oching</div>
          </div>
        ) : loading ? (
          <div className="card"><div className="sk sk-para" /></div>
        ) : threads.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">💬</div>
            <div className="empty-title">Hali suhbat yo'q</div>
            <div className="empty-desc">Mahsulot sahifasidan sotuvchiga yozing</div>
          </div>
        ) : (
          <div className="card" style={{ padding: 0 }}>
            {threads.map((t, i) => (
              <Link
                key={t.sellerId}
                href={`/messages/${t.sellerId}`}
                className="list-item"
                style={{ borderBottom: i < threads.length - 1 ? '1px solid var(--border)' : 'none' }}
              >
                <div className="seller-avatar" style={{ width: 38, height: 38, fontSize: 15 }}>
                  {t.sellerName.charAt(0).toUpperCase()}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="row-sb">
                    <span style={{ fontWeight: 700, fontSize: 13.5 }}>{t.sellerName}</span>
                    <span className="text-xs muted">{formatDate(t.lastMessageAt)}</span>
                  </div>
                  <div
                    className="text-sm muted"
                    style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                  >
                    {t.lastMessage}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
