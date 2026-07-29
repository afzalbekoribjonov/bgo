'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { formatDate, getPartners, updatePartnerStatus } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import type { PartnerApplication } from '@/lib/types';

const STATUS_META: Record<PartnerApplication['status'], { label: string; color: string }> = {
  PENDING:  { label: 'Kutilmoqda', color: 'var(--amber)' },
  APPROVED: { label: 'Tasdiqlandi', color: 'var(--green)' },
  REJECTED: { label: 'Rad etildi',  color: 'var(--red)' },
};

const TYPE_META: Record<PartnerApplication['type'], { label: string; icon: string }> = {
  RESTAURANT: { label: 'Oshxona', icon: '🏪' },
  DRIVER:     { label: 'Haydovchi', icon: '🚗' },
};

export default function PartnersPage() {
  const toast = useToast();
  const dialog = useDialog();
  const [apps, setApps] = useState<PartnerApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<PartnerApplication['status'] | 'all'>('all');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setApps(await getPartners());
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  async function act(a: PartnerApplication, newStatus: 'APPROVED' | 'REJECTED') {
    const verb = newStatus === 'APPROVED' ? 'tasdiqlaysizmi' : 'rad etasizmi';
    const ok = await dialog.confirm(
      `"${a.fullName}" arizasini ${verb}?`,
      { title: newStatus === 'APPROVED' ? 'Tasdiqlash' : 'Rad etish', danger: newStatus === 'REJECTED' },
    );
    if (!ok) return;
    try {
      await updatePartnerStatus(a.id, newStatus);
      toast(newStatus === 'APPROVED' ? 'Tasdiqlandi' : 'Rad etildi', 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  const filtered = useMemo(() =>
    apps.filter((a) => filterStatus === 'all' || a.status === filterStatus),
  [apps, filterStatus]);

  const stats = useMemo(() => ({
    pending: apps.filter((a) => a.status === 'PENDING').length,
    approved: apps.filter((a) => a.status === 'APPROVED').length,
    rejected: apps.filter((a) => a.status === 'REJECTED').length,
  }), [apps]);

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Hamkorlik arizalari</h1>
          <p className="page-subtitle">{apps.length} ta ariza</p>
        </div>
      </div>

      <div className="stats">
        <div className="stat-card">
          <div className="stat-label">⏳ Kutilmoqda</div>
          <div className="stat-value" style={{ color: 'var(--amber)' }}>{stats.pending}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">✅ Tasdiqlangan</div>
          <div className="stat-value text-green">{stats.approved}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">❌ Rad etilgan</div>
          <div className="stat-value" style={{ color: 'var(--red)' }}>{stats.rejected}</div>
        </div>
      </div>

      {stats.pending > 0 && (
        <div className="info-block amber" style={{ marginBottom: 16, display: 'flex', gap: 10, alignItems: 'center' }}>
          <span style={{ fontSize: 18 }}>⚠️</span>
          <span style={{ fontSize: 13.5, fontWeight: 600 }}>
            {stats.pending} ta yangi ariza ko'rib chiqilishni kutmoqda
          </span>
        </div>
      )}

      <div className="filters" style={{ marginBottom: 16 }}>
        {(['all', 'PENDING', 'APPROVED', 'REJECTED'] as const).map((f) => (
          <button
            key={f}
            className={`chip ${filterStatus === f ? 'active' : ''}`}
            onClick={() => setFilterStatus(f)}
          >
            {f === 'all' ? 'Barchasi' : STATUS_META[f].label}
          </button>
        ))}
      </div>

      {loading ? (
        <div>
          {[...Array(5)].map((_, i) => (
            <div key={i} className="card" style={{ marginBottom: 8, padding: '16px 20px' }}>
              <div className="sk sk-line" style={{ width: '30%', marginBottom: 8, height: 15 }} />
              <div className="sk sk-line sk-line-md" style={{ height: 12 }} />
            </div>
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">📋</div>
            <div className="empty-title">Ariza topilmadi</div>
            <div className="empty-desc">Filtrni o'zgartiring yoki yangi arizalar kuting</div>
          </div>
        </div>
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {filtered.map((a, i) => {
            const st = STATUS_META[a.status];
            const tp = TYPE_META[a.type];
            return (
              <div
                key={a.id}
                style={{
                  display: 'flex',
                  gap: 14,
                  padding: '16px 20px',
                  borderBottom: i < filtered.length - 1 ? '1px solid var(--border)' : 'none',
                  alignItems: 'flex-start',
                }}
              >
                {/* Type icon */}
                <div
                  style={{
                    width: 42,
                    height: 42,
                    borderRadius: '50%',
                    background: 'var(--surface-2)',
                    border: '1px solid var(--border)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: 20,
                    flexShrink: 0,
                  }}
                >
                  {tp.icon}
                </div>

                {/* Main info */}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', marginBottom: 4 }}>
                    <span style={{ fontWeight: 700, fontSize: 14, color: 'var(--text)' }}>{a.fullName}</span>
                    <span
                      style={{
                        fontSize: 11.5,
                        background: 'var(--surface-2)',
                        border: '1px solid var(--border)',
                        padding: '2px 7px',
                        borderRadius: 5,
                        color: 'var(--text-3)',
                      }}
                    >
                      {tp.label}
                    </span>
                  </div>
                  <div style={{ fontSize: 13, color: 'var(--text-muted)', marginBottom: 4 }}>
                    📞 {a.phone}
                  </div>
                  {a.note && (
                    <div
                      style={{
                        fontSize: 13,
                        color: 'var(--text-3)',
                        background: 'var(--surface-2)',
                        padding: '8px 12px',
                        borderRadius: 8,
                        borderLeft: '3px solid var(--border)',
                        marginBottom: 4,
                        fontStyle: 'italic',
                      }}
                    >
                      "{a.note}"
                    </div>
                  )}
                  <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                    {formatDate(a.createdAt)}
                  </div>
                </div>

                {/* Status + actions */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-end', flexShrink: 0 }}>
                  <span
                    className="badge"
                    style={{ background: st.color, fontSize: 11.5 }}
                  >
                    {st.label}
                  </span>
                  {a.status === 'PENDING' && (
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button
                        className="btn btn-sm green"
                        onClick={() => act(a, 'APPROVED')}
                      >
                        ✓ Tasdiqlash
                      </button>
                      <button
                        className="btn btn-sm red"
                        onClick={() => act(a, 'REJECTED')}
                      >
                        ✕ Rad
                      </button>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
