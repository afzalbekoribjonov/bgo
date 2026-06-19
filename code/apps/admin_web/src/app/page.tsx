'use client';

import { useEffect, useState } from 'react';
import { formatSom, getStats } from '@/lib/api';
import { statusColor, statusLabel } from '@/lib/status';
import type { Stats } from '@/lib/types';

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getStats()
      .then(setStats)
      .catch((e) => setError(e.message));
  }, []);

  return (
    <div className="container">
      <h1 className="h1">Dashboard</h1>
      {error && <p className="error">{error}</p>}
      {!stats && !error && <p className="muted">Yuklanmoqda…</p>}
      {stats && (
        <>
          <div className="stats">
            <Stat label="Jami buyurtma" value={String(stats.totalOrders)} />
            <Stat label="Faol buyurtma" value={String(stats.activeOrders)} />
            <Stat label="Bugungi buyurtma" value={String(stats.todayOrders)} />
            <Stat label="Aylanma (yetkazilgan)" value={formatSom(stats.revenue)} />
          </div>

          <div className="card">
            <strong>Holat bo&apos;yicha taqsimot</strong>
            <div style={{ marginTop: 12, display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {Object.entries(stats.byStatus).map(([status, count]) => (
                <span
                  key={status}
                  className="badge"
                  style={{ background: statusColor(status) }}
                >
                  {statusLabel(status)}: {count}
                </span>
              ))}
              {Object.keys(stats.byStatus).length === 0 && (
                <span className="muted">Hozircha buyurtma yo&apos;q</span>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="stat">
      <div className="label">{label}</div>
      <div className="value">{value}</div>
    </div>
  );
}
