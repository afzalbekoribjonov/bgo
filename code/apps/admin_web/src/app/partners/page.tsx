'use client';

import { useCallback, useEffect, useState } from 'react';
import { formatDate, getPartners, updatePartnerStatus } from '@/lib/api';
import type { PartnerApplication } from '@/lib/types';

const STATUS_FILTERS = [
  { key: '', label: 'Hammasi' },
  { key: 'PENDING', label: 'Kutilmoqda' },
  { key: 'APPROVED', label: 'Tasdiqlangan' },
  { key: 'REJECTED', label: 'Rad etilgan' },
];

const STATUS_LABEL: Record<PartnerApplication['status'], string> = {
  PENDING: 'Kutilmoqda',
  APPROVED: 'Tasdiqlandi',
  REJECTED: 'Rad etildi',
};

const STATUS_COLOR: Record<PartnerApplication['status'], string> = {
  PENDING: '#b45309',
  APPROVED: 'green',
  REJECTED: '#b91c1c',
};

export default function PartnersPage() {
  const [apps, setApps] = useState<PartnerApplication[]>([]);
  const [status, setStatus] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setApps(await getPartners(status || undefined));
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    }
  }, [status]);

  useEffect(() => {
    load();
  }, [load]);

  async function decide(id: string, next: 'APPROVED' | 'REJECTED') {
    setBusy(id);
    try {
      await updatePartnerStatus(id, next);
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="container">
      <h1 className="h1">Hamkorlik arizalari</h1>
      {error && <p className="error">{error}</p>}

      <div className="btn-group" style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.key}
            className={`btn ${status === f.key ? '' : 'ghost'}`}
            onClick={() => setStatus(f.key)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {apps.length === 0 && !error && <p className="muted">Ariza yo&apos;q</p>}
      {apps.map((a) => (
        <div className="card" key={a.id}>
          <div
            className="row"
            style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}
          >
            <div>
              <strong>{a.fullName}</strong>{' '}
              <span className="muted">
                {a.type === 'DRIVER' ? 'Haydovchi' : 'Oshxona'} · {a.phone}
                {a.note ? ` · ${a.note}` : ''}
              </span>
              <div className="muted" style={{ fontSize: 12 }}>
                {formatDate(a.createdAt)}
              </div>
            </div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              {a.status === 'PENDING' ? (
                <>
                  <button
                    className="btn green"
                    disabled={busy === a.id}
                    onClick={() => decide(a.id, 'APPROVED')}
                  >
                    Tasdiqlash
                  </button>
                  <button
                    className="btn red"
                    disabled={busy === a.id}
                    onClick={() => decide(a.id, 'REJECTED')}
                  >
                    Rad etish
                  </button>
                </>
              ) : (
                <span style={{ color: STATUS_COLOR[a.status], fontWeight: 600 }}>
                  {STATUS_LABEL[a.status]}
                </span>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
