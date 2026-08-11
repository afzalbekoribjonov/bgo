'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import {
  createSupportFaqItem,
  deleteSupportConversation,
  deleteSupportFaqItem,
  getSupportConversationMessages,
  getSupportConversations,
  getSupportFaqItems,
  sendSupportAdminReply,
  updateSupportFaqItem,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import type {
  I18nString,
  SupportChatMessage,
  SupportConversation,
  SupportConversationStatus,
  SupportFaqItem,
  SupportUserRole,
} from '@/lib/types';

type Tab = 'conversations' | 'faq';
const TABS: { id: Tab; label: string }[] = [
  { id: 'conversations', label: 'Suhbatlar' },
  { id: 'faq', label: 'Savol-javoblar' },
];

export default function SupportPage() {
  const [tab, setTab] = useState<Tab>('conversations');

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Yordam</h1>
          <p className="page-subtitle">
            AI qo&apos;llab-quvvatlash suhbatlari (mijoz + haydovchi) va tayyor savol-javoblar
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

      {tab === 'conversations' && <ConversationsTab />}
      {tab === 'faq' && <FaqTab />}
    </div>
  );
}

/* ============ Suhbatlar ============ */

const CHAT_LIST_POLL_MS = 5000;
const CHAT_MSG_POLL_MS = 3000;

const STATUS_LABEL: Record<SupportConversationStatus, string> = {
  OPEN: 'Ochiq',
  ESCALATED: 'Adminga yuborilgan',
  RESOLVED: 'Yechilgan',
};
const STATUS_FILTERS: { id: SupportConversationStatus | 'all'; label: string }[] = [
  { id: 'all', label: 'Barchasi' },
  { id: 'ESCALATED', label: 'Adminga yuborilgan' },
  { id: 'OPEN', label: 'Ochiq' },
  { id: 'RESOLVED', label: 'Yechilgan' },
];
const ROLE_FILTERS: { id: SupportUserRole | 'all'; label: string }[] = [
  { id: 'all', label: 'Barcha turlar' },
  { id: 'CUSTOMER', label: '👤 Mijoz' },
  { id: 'DRIVER', label: '🚗 Haydovchi' },
];
const SENDER_LABEL: Partial<Record<SupportChatMessage['senderRole'], string>> = {
  BOT: 'Bot (tayyor javob)',
  AI: 'AI yordamchi',
  ADMIN: 'Admin',
  SYSTEM: 'Tizim',
};

function convTitle(c: SupportConversation): string {
  if (c.topic === 'ai') return "Erkin suhbat (AI)";
  return c.topicLabel || 'Savol-javob';
}

function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString('ru-RU');
}

function ConversationsTab() {
  const toast = useToast();
  const [conversations, setConversations] = useState<SupportConversation[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<SupportConversationStatus | 'all'>('all');
  const [roleFilter, setRoleFilter] = useState<SupportUserRole | 'all'>('all');
  const [selected, setSelected] = useState<string | null>(null);
  const [selectedConv, setSelectedConv] = useState<SupportConversation | null>(null);
  const [messages, setMessages] = useState<SupportChatMessage[]>([]);
  const [reply, setReply] = useState('');
  const [sending, setSending] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const selectedRef = useRef<string | null>(null);
  selectedRef.current = selected;

  const loadList = useCallback(
    async (silent = false) => {
      if (!silent) setLoading(true);
      try {
        const res = await getSupportConversations({
          status: statusFilter === 'all' ? undefined : statusFilter,
          role: roleFilter === 'all' ? undefined : roleFilter,
          pageSize: 50,
        });
        setConversations(res.items);
      } catch (e) {
        if (!silent) toast((e as Error).message, 'error');
      } finally {
        if (!silent) setLoading(false);
      }
    },
    [statusFilter, roleFilter, toast],
  );

  useEffect(() => {
    loadList();
    const t = setInterval(() => loadList(true), CHAT_LIST_POLL_MS);
    return () => clearInterval(t);
  }, [loadList]);

  const openConversation = useCallback(
    async (id: string, silent = false) => {
      if (!silent) setSelected(id);
      try {
        const res = await getSupportConversationMessages(id);
        if (selectedRef.current === id || !silent) {
          setSelectedConv(res.conversation);
          setMessages(res.messages);
        }
      } catch (e) {
        if (!silent) toast((e as Error).message, 'error');
      }
    },
    [toast],
  );

  useEffect(() => {
    if (!selected) return;
    const t = setInterval(() => openConversation(selected, true), CHAT_MSG_POLL_MS);
    return () => clearInterval(t);
  }, [selected, openConversation]);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight });
  }, [messages]);

  /** Suhbatni butunlay o'chirish — xabarlari bilan, qaytarib bo'lmaydi. */
  async function removeConversation() {
    if (!selected || !selectedConv) return;
    const who = selectedConv.userInfo?.fullName || 'Foydalanuvchi';
    if (
      !confirm(
        `${who} bilan bo'lgan suhbatni butunlay o'chirasizmi?\n\n` +
          "Barcha xabarlar ham o'chadi. Bu amalni qaytarib bo'lmaydi.",
      )
    ) {
      return;
    }
    setDeleting(true);
    try {
      await deleteSupportConversation(selected);
      toast("Suhbat o'chirildi", 'success');
      setSelected(null);
      setSelectedConv(null);
      setMessages([]);
      await loadList(true);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setDeleting(false);
    }
  }

  async function send() {
    if (!selected || !reply.trim()) return;
    setSending(true);
    try {
      await sendSupportAdminReply(selected, reply.trim());
      setReply('');
      await openConversation(selected);
      await loadList(true);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setSending(false);
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
            {f.id === 'ESCALATED' && '🔴 '}
            {f.label}
          </button>
        ))}
      </div>
      <div className="filters" style={{ marginBottom: 14 }}>
        {ROLE_FILTERS.map((f) => (
          <button
            key={f.id}
            className={`chip ${roleFilter === f.id ? 'active' : ''}`}
            onClick={() => setRoleFilter(f.id)}
          >
            {f.label}
          </button>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '320px 1fr', gap: 16, minHeight: 480 }}>
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {loading ? (
            <div style={{ padding: 16 }}>
              <div className="sk sk-para" />
            </div>
          ) : conversations.length === 0 ? (
            <div className="empty">
              <div className="empty-icon">💬</div>
              <div className="empty-title">Suhbat yo&apos;q</div>
            </div>
          ) : (
            conversations.map((c) => (
              <button
                key={c.id}
                onClick={() => openConversation(c.id)}
                className="list-item"
                style={{
                  width: '100%',
                  border: 'none',
                  background: selected === c.id ? 'var(--surface-hover)' : 'transparent',
                  cursor: 'pointer',
                  borderBottom: '1px solid var(--border)',
                }}
              >
                <div style={{ flex: 1, minWidth: 0, textAlign: 'left' }}>
                  <div className="row-sb" style={{ gap: 6 }}>
                    <div
                      className="text-sm font-semi"
                      style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                    >
                      {c.userRole === 'DRIVER' ? '🚗' : '👤'}{' '}
                      {c.userInfo?.fullName || c.userInfo?.phone || c.userId.slice(0, 8)}
                    </div>
                    {c.status === 'ESCALATED' && (
                      <span className="badge" style={{ background: 'var(--red)', flexShrink: 0 }}>
                        !
                      </span>
                    )}
                  </div>
                  <div
                    className="text-xs muted"
                    style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                  >
                    {convTitle(c)}
                  </div>
                  <div className="text-xs muted">{formatDateTime(c.updatedAt)}</div>
                </div>
              </button>
            ))
          )}
        </div>

        <div className="card" style={{ display: 'flex', flexDirection: 'column', padding: 0, overflow: 'hidden' }}>
          {!selected || !selectedConv ? (
            <div className="empty" style={{ margin: 'auto' }}>
              <div className="empty-icon">👈</div>
              <div className="empty-title">Suhbatni tanlang</div>
            </div>
          ) : (
            <>
              <div className="row-sb" style={{ padding: '12px 16px', borderBottom: '1px solid var(--border)', flexShrink: 0 }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 14.5 }}>
                    {selectedConv.userRole === 'DRIVER' ? '🚗' : '👤'}{' '}
                    {selectedConv.userInfo?.fullName || 'Foydalanuvchi'}
                  </div>
                  <div className="text-xs muted">
                    {selectedConv.userInfo?.phone} · {convTitle(selectedConv)}
                  </div>
                </div>
                <div className="row" style={{ gap: 8 }}>
                  <span
                    className="badge"
                    style={{
                      background:
                        selectedConv.status === 'ESCALATED'
                          ? 'var(--red-light)'
                          : selectedConv.status === 'RESOLVED'
                          ? 'var(--green-light)'
                          : 'var(--surface-2)',
                      color:
                        selectedConv.status === 'ESCALATED'
                          ? '#991b1b'
                          : selectedConv.status === 'RESOLVED'
                          ? '#166534'
                          : 'var(--text-2)',
                    }}
                  >
                    {STATUS_LABEL[selectedConv.status]}
                  </span>
                  {selectedConv.userInfo?.phone && (
                    <a href={`tel:${selectedConv.userInfo.phone}`} className="btn ghost btn-sm">
                      📞
                    </a>
                  )}
                  <button
                    className="btn ghost btn-sm"
                    title="Suhbatni butunlay o'chirish"
                    aria-label="Suhbatni butunlay o'chirish"
                    disabled={deleting}
                    onClick={removeConversation}
                    style={{ color: 'var(--red)', borderColor: 'var(--red)', opacity: deleting ? 0.5 : 1 }}
                  >
                    {deleting ? '…' : '🗑'}
                  </button>
                </div>
              </div>
              <div
                ref={scrollRef}
                style={{ flex: 1, padding: 16, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 8 }}
              >
                {messages.map((m) => {
                  if (m.senderRole === 'SYSTEM') {
                    return (
                      <div
                        key={m.id}
                        style={{
                          alignSelf: 'center',
                          background: 'var(--amber-light)',
                          color: '#92400e',
                          padding: '6px 12px',
                          borderRadius: 20,
                          fontSize: 12,
                          fontWeight: 600,
                          textAlign: 'center',
                          maxWidth: '85%',
                        }}
                      >
                        {m.text}
                      </div>
                    );
                  }
                  const mine = m.senderRole === 'ADMIN';
                  return (
                    <div key={m.id} style={{ alignSelf: mine ? 'flex-end' : 'flex-start', maxWidth: '75%' }}>
                      {SENDER_LABEL[m.senderRole] && (
                        <div className="text-xs muted" style={{ marginBottom: 2, textAlign: mine ? 'right' : 'left' }}>
                          {SENDER_LABEL[m.senderRole]}
                        </div>
                      )}
                      <div
                        style={{
                          background: mine ? 'var(--primary)' : 'var(--surface-2)',
                          color: mine ? '#fff' : 'var(--text)',
                          padding: '8px 12px',
                          borderRadius: 12,
                          fontSize: 13.5,
                        }}
                      >
                        {m.text}
                      </div>
                      <div className="text-xs muted" style={{ marginTop: 2, textAlign: mine ? 'right' : 'left' }}>
                        {formatDateTime(m.createdAt)}
                      </div>
                    </div>
                  );
                })}
              </div>
              <div className="row" style={{ padding: 14, borderTop: '1px solid var(--border)', flexShrink: 0 }}>
                <input
                  value={reply}
                  placeholder="Javob yozing..."
                  onChange={(e) => setReply(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') send();
                  }}
                />
                <button className="btn" disabled={sending || !reply.trim()} onClick={send}>
                  Yuborish
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

/* ============ Savol-javoblar (FAQ) ============ */

const EMPTY_I18N: I18nString = { uz: '' };

function FaqTab() {
  const toast = useToast();
  const dialog = useDialog();
  const [items, setItems] = useState<SupportFaqItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<SupportFaqItem | null>(null);
  const [busy, setBusy] = useState(false);

  const [label, setLabel] = useState<I18nString>(EMPTY_I18N);
  const [answer, setAnswer] = useState<I18nString>(EMPTY_I18N);
  const [roles, setRoles] = useState<SupportUserRole[]>([]);
  const [sortOrder, setSortOrder] = useState('0');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setItems(await getSupportFaqItems());
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    load();
  }, [load]);

  function resetForm() {
    setLabel(EMPTY_I18N);
    setAnswer(EMPTY_I18N);
    setRoles([]);
    setSortOrder('0');
    setEditing(null);
    setShowForm(false);
  }

  function startEdit(item: SupportFaqItem) {
    setEditing(item);
    setLabel(item.label);
    setAnswer(item.answer);
    setRoles(item.roles);
    setSortOrder(String(item.sortOrder));
    setShowForm(true);
  }

  async function save() {
    if (!label.uz.trim() || !answer.uz.trim()) {
      toast("Savol va javob matni (uz) to'ldirilishi shart", 'error');
      return;
    }
    setBusy(true);
    try {
      const dto = { label, answer, roles, sortOrder: Number(sortOrder) || 0 };
      if (editing) {
        await updateSupportFaqItem(editing.id, dto);
        toast('Yangilandi', 'success');
      } else {
        await createSupportFaqItem(dto);
        toast('Qo\'shildi', 'success');
      }
      resetForm();
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(false);
    }
  }

  async function toggleActive(item: SupportFaqItem) {
    try {
      await updateSupportFaqItem(item.id, { isActive: !item.isActive });
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  async function remove(item: SupportFaqItem) {
    const ok = await dialog.confirm(`"${item.label.uz}" savolini o'chirasizmi?`, {
      title: "Savolni o'chirish",
      danger: true,
    });
    if (!ok) return;
    try {
      await deleteSupportFaqItem(item.id);
      toast("O'chirildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  function toggleRole(r: SupportUserRole) {
    setRoles((prev) => (prev.includes(r) ? prev.filter((x) => x !== r) : [...prev, r]));
  }

  return (
    <div>
      <div className="row-sb" style={{ marginBottom: 14 }}>
        <div className="text-sm muted">
          Mijoz/haydovchi ilovasida "Savolim bor" ekranida ko'rinadigan tayyor tugmalar va ularning
          javoblari
        </div>
        <button className="btn btn-sm" onClick={() => (showForm ? resetForm() : setShowForm(true))}>
          {showForm ? 'Bekor qilish' : '+ Yangi savol'}
        </button>
      </div>

      {showForm && (
        <div className="card card-p" style={{ marginBottom: 16 }}>
          <div className="form-grid form-grid-3">
            <div>
              <label>Savol (uz) *</label>
              <input value={label.uz} onChange={(e) => setLabel({ ...label, uz: e.target.value })} />
            </div>
            <div>
              <label>Savol (кирилл)</label>
              <input
                value={label.uz_Cyrl ?? ''}
                onChange={(e) => setLabel({ ...label, uz_Cyrl: e.target.value })}
              />
            </div>
            <div>
              <label>Savol (ru)</label>
              <input value={label.ru ?? ''} onChange={(e) => setLabel({ ...label, ru: e.target.value })} />
            </div>
          </div>
          <div style={{ marginTop: 10 }}>
            <label>Javob (uz) *</label>
            <textarea
              rows={2}
              value={answer.uz}
              onChange={(e) => setAnswer({ ...answer, uz: e.target.value })}
            />
          </div>
          <div className="form-grid form-grid-3" style={{ marginTop: 10 }}>
            <div>
              <label>Javob (кирилл)</label>
              <textarea
                rows={2}
                value={answer.uz_Cyrl ?? ''}
                onChange={(e) => setAnswer({ ...answer, uz_Cyrl: e.target.value })}
              />
            </div>
            <div>
              <label>Javob (ru)</label>
              <textarea
                rows={2}
                value={answer.ru ?? ''}
                onChange={(e) => setAnswer({ ...answer, ru: e.target.value })}
              />
            </div>
            <div>
              <label>Tartib raqami</label>
              <input
                type="number"
                value={sortOrder}
                onChange={(e) => setSortOrder(e.target.value)}
              />
            </div>
          </div>
          <div style={{ marginTop: 10 }}>
            <label>Kimga ko&apos;rinadi (bo&apos;sh — ikkalasiga ham)</label>
            <div className="filters">
              <button
                type="button"
                className={`chip ${roles.includes('CUSTOMER') ? 'active' : ''}`}
                onClick={() => toggleRole('CUSTOMER')}
              >
                👤 Mijoz
              </button>
              <button
                type="button"
                className={`chip ${roles.includes('DRIVER') ? 'active' : ''}`}
                onClick={() => toggleRole('DRIVER')}
              >
                🚗 Haydovchi
              </button>
            </div>
          </div>
          <div className="row" style={{ marginTop: 14 }}>
            <button className="btn" disabled={busy} onClick={save}>
              {busy ? 'Saqlanmoqda…' : editing ? 'Saqlash' : "Qo'shish"}
            </button>
          </div>
        </div>
      )}

      {loading ? (
        <div className="sk sk-para" />
      ) : items.length === 0 ? (
        <div className="empty">
          <div className="empty-icon">❓</div>
          <div className="empty-title">Hali savol qo&apos;shilmagan</div>
        </div>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Savol</th>
              <th>Javob</th>
              <th>Kimga</th>
              <th>Holat</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={item.id}>
                <td className="text-sm font-semi">{item.label.uz}</td>
                <td className="text-sm muted" style={{ maxWidth: 320 }}>
                  {item.answer.uz}
                </td>
                <td className="text-xs muted">
                  {item.roles.length === 0
                    ? 'Hammaga'
                    : item.roles.map((r) => (r === 'CUSTOMER' ? '👤' : '🚗')).join(' ')}
                </td>
                <td>
                  <button
                    className={`chip ${item.isActive ? 'active' : ''}`}
                    onClick={() => toggleActive(item)}
                  >
                    {item.isActive ? 'Faol' : "O'chiq"}
                  </button>
                </td>
                <td>
                  <div className="row" style={{ gap: 6 }}>
                    <button className="btn ghost btn-sm" onClick={() => startEdit(item)}>
                      ✏️
                    </button>
                    <button className="btn ghost btn-sm" onClick={() => remove(item)}>
                      🗑
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
