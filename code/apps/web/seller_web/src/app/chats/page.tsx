'use client';

import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { formatDate, getChatThreads } from '@/lib/api';
import { useToast } from '@/components/toast';
import type { ChatThread } from '@/lib/types';

export default function ChatsPage() {
  const toast = useToast();
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
    load();
    const t = setInterval(load, 8000);
    return () => clearInterval(t);
  }, [load]);

  return (
    <>
      <div className="topbar">
        <span className="topbar-title">💬 Suhbatlar</span>
      </div>
      <div className="content">
        {loading ? (
          <div className="card"><div className="sk sk-para" /></div>
        ) : threads.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">💬</div>
            <div className="empty-title">Hali xabar yo'q</div>
            <div className="empty-desc">Mijozlar sizga yozganda shu yerda ko'rinadi</div>
          </div>
        ) : (
          <div className="card" style={{ padding: 0 }}>
            {threads.map((t, i) => (
              <Link
                key={t.customerId}
                href={`/chats/${t.customerId}`}
                className="list-item"
                style={{ borderBottom: i < threads.length - 1 ? '1px solid var(--border)' : 'none' }}
              >
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="row-sb">
                    <span style={{ fontWeight: 700, fontSize: 13.5 }}>Mijoz</span>
                    <span className="text-xs muted">{formatDate(t.lastMessageAt)}</span>
                  </div>
                  <div
                    className="text-sm muted"
                    style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                  >
                    {t.lastMessage}
                  </div>
                </div>
                {t.unseenCount > 0 && (
                  <span
                    className="status-badge"
                    style={{ background: 'var(--brand)', color: '#fff' }}
                  >
                    {t.unseenCount}
                  </span>
                )}
              </Link>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
