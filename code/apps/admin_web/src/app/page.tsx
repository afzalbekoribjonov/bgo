'use client';

import { useEffect, useState } from 'react';
import { formatSom, getReport, getStats } from '@/lib/api';
import { statusColor, statusLabel } from '@/lib/status';
import type { Report, ReportPeriod, Stats } from '@/lib/types';

const PERIODS: { key: ReportPeriod; label: string }[] = [
  { key: 'today', label: 'Bugun' },
  { key: 'week', label: 'Hafta' },
  { key: 'month', label: 'Oy' },
];

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [report, setReport] = useState<Report | null>(null);
  const [period, setPeriod] = useState<ReportPeriod>('week');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getStats()
      .then(setStats)
      .catch((e) => setError(e.message));
  }, []);

  useEffect(() => {
    getReport(period)
      .then(setReport)
      .catch((e) => setError(e.message));
  }, [period]);

  return (
    <div className="container">
      <h1 className="h1">Dashboard</h1>
      {error && <p className="error">{error}</p>}
      {!stats && !error && <p className="muted">Yuklanmoqda…</p>}
      {stats && (
        <div className="stats">
          <Stat label="Jami buyurtma" value={String(stats.totalOrders)} />
          <Stat label="Faol buyurtma" value={String(stats.activeOrders)} />
          <Stat label="Bugungi buyurtma" value={String(stats.todayOrders)} />
          <Stat label="Aylanma (jami)" value={formatSom(stats.revenue)} />
          <Stat label="Foyda (jami)" value={formatSom(stats.profit)} />
        </div>
      )}

      <div className="card" style={{ marginTop: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
          <strong>Davr hisoboti</strong>
          <div className="filters" style={{ margin: 0 }}>
            {PERIODS.map((p) => (
              <button
                key={p.key}
                className={`chip ${period === p.key ? 'active' : ''}`}
                onClick={() => setPeriod(p.key)}
              >
                {p.label}
              </button>
            ))}
          </div>
        </div>

        {report && (
          <>
            <div className="stats" style={{ marginTop: 12 }}>
              <Stat label="Buyurtmalar" value={String(report.summary.totalOrders)} />
              <Stat label="Yetkazilgan" value={String(report.summary.delivered)} />
              <Stat label="Bekor qilingan" value={String(report.summary.cancelled)} />
              <Stat label="Aylanma" value={formatSom(report.summary.revenue)} />
              <Stat label="Foyda" value={formatSom(report.summary.profit)} />
              <Stat label="O'rtacha chek" value={formatSom(report.summary.avgOrder)} />
            </div>
            {report.byVertical && (
              <div style={{ marginTop: 16 }}>
                <div className="muted" style={{ fontSize: 13, marginBottom: 8 }}>
                  Yo&apos;nalish bo&apos;yicha (aylanma · foyda)
                </div>
                <div className="stats">
                  <VerticalCard
                    icon="🍽"
                    label="Ovqat"
                    revenue={report.byVertical.food.revenue}
                    profit={report.byVertical.food.profit}
                  />
                  <VerticalCard
                    icon="🚕"
                    label="Taksi"
                    revenue={report.byVertical.taxi.revenue}
                    profit={report.byVertical.taxi.profit}
                  />
                  <VerticalCard
                    icon="📦"
                    label="Dostavka"
                    revenue={report.byVertical.parcel.revenue}
                    profit={report.byVertical.parcel.profit}
                  />
                </div>
              </div>
            )}
            {report.daily.length > 1 && <DailyChart report={report} />}
          </>
        )}
      </div>

      {stats && (
        <div className="card" style={{ marginTop: 16 }}>
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
      )}
    </div>
  );
}

/** Oddiy ustunli grafik — kunlik buyurtmalar soni. */
function DailyChart({ report }: { report: Report }) {
  const max = Math.max(1, ...report.daily.map((d) => d.orders));
  return (
    <div style={{ marginTop: 16 }}>
      <div className="muted" style={{ fontSize: 13, marginBottom: 8 }}>
        Kunlik buyurtmalar
      </div>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 4, height: 120 }}>
        {report.daily.map((d) => (
          <div
            key={d.date}
            title={`${d.date}: ${d.orders} ta · ${formatSom(d.revenue)}`}
            style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}
          >
            <div style={{ fontSize: 11, color: 'var(--muted, #888)' }}>{d.orders || ''}</div>
            <div
              style={{
                width: '100%',
                height: `${(d.orders / max) * 90}px`,
                minHeight: d.orders > 0 ? 4 : 0,
                background: 'var(--accent, #2563eb)',
                borderRadius: '4px 4px 0 0',
              }}
            />
            <div style={{ fontSize: 10, color: 'var(--muted, #888)', transform: 'rotate(-45deg)', whiteSpace: 'nowrap' }}>
              {d.date.slice(5)}
            </div>
          </div>
        ))}
      </div>
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

function VerticalCard({
  icon,
  label,
  revenue,
  profit,
}: {
  icon: string;
  label: string;
  revenue: number;
  profit: number;
}) {
  return (
    <div className="stat">
      <div className="label">
        {icon} {label}
      </div>
      <div className="value" style={{ fontSize: 18 }}>{formatSom(revenue)}</div>
      <div className="muted" style={{ fontSize: 12 }}>
        Foyda: {formatSom(profit)}
      </div>
    </div>
  );
}
