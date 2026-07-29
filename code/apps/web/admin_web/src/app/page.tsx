'use client';

import { useEffect, useState } from 'react';
import { formatSom, getReport, getStats } from '@/lib/api';
import { statusColor, statusLabel } from '@/lib/status';
import { useToast } from '@/components/toast';
import type { Report, ReportPeriod, Stats } from '@/lib/types';

const PERIODS: { key: ReportPeriod; label: string }[] = [
  { key: 'today', label: 'Bugun' },
  { key: 'week', label: 'Hafta' },
  { key: 'month', label: 'Oy' },
];

export default function DashboardPage() {
  const toast = useToast();
  const [stats, setStats] = useState<Stats | null>(null);
  const [report, setReport] = useState<Report | null>(null);
  const [period, setPeriod] = useState<ReportPeriod>('week');
  const [loadingStats, setLoadingStats] = useState(true);
  const [loadingReport, setLoadingReport] = useState(true);

  useEffect(() => {
    setLoadingStats(true);
    getStats()
      .then(setStats)
      .catch((e) => toast(e.message, 'error'))
      .finally(() => setLoadingStats(false));
  }, [toast]);

  useEffect(() => {
    setLoadingReport(true);
    setReport(null);
    getReport(period)
      .then(setReport)
      .catch((e) => toast(e.message, 'error'))
      .finally(() => setLoadingReport(false));
  }, [period, toast]);

  return (
    <div className="container">
      {/* Header */}
      <div className="page-header">
        <div>
          <h1 className="page-title">Dashboard</h1>
          <p className="page-subtitle">Umumiy holat va statistika</p>
        </div>
      </div>

      {/* Stats */}
      {loadingStats ? (
        <div className="stats" style={{ marginBottom: 20 }}>
          {[...Array(5)].map((_, i) => (
            <div key={i} className="stat-card">
              <div className="sk sk-line sk-line-sm" style={{ marginBottom: 10 }} />
              <div className="sk sk-line" style={{ height: 28, width: '70%' }} />
            </div>
          ))}
        </div>
      ) : stats ? (
        <div className="stats">
          <StatCard
            label="Jami buyurtma"
            value={stats.totalOrders.toLocaleString('ru-RU')}
            color="#3b82f6"
            icon="📦"
          />
          <StatCard
            label="Faol buyurtma"
            value={String(stats.activeOrders)}
            color="#d97706"
            icon="⚡"
          />
          <StatCard
            label="Bugungi buyurtma"
            value={String(stats.todayOrders)}
            color="#8b5cf6"
            icon="📅"
          />
          <StatCard
            label="Jami aylanma"
            value={formatSom(stats.revenue)}
            color="#16a34a"
            icon="💰"
          />
          <StatCard
            label="Jami foyda"
            value={formatSom(stats.profit)}
            color="#0891b2"
            icon="📈"
          />
        </div>
      ) : null}

      {/* Period report */}
      <div className="card" style={{ marginBottom: 20 }}>
        <div className="card-header">
          <span className="card-title">Davr hisoboti</span>
          <div style={{ display: 'flex', gap: 4 }}>
            {PERIODS.map((p) => (
              <button
                key={p.key}
                className={`chip ${period === p.key ? 'active' : ''}`}
                style={{ padding: '5px 12px', fontSize: 12.5 }}
                onClick={() => setPeriod(p.key)}
              >
                {p.label}
              </button>
            ))}
          </div>
        </div>

        <div className="card-body">
          {loadingReport ? (
            <div>
              <div className="stats" style={{ marginBottom: 16 }}>
                {[...Array(5)].map((_, i) => (
                  <div key={i} className="stat-card">
                    <div className="sk sk-line sk-line-sm" style={{ marginBottom: 8 }} />
                    <div className="sk sk-line" style={{ height: 22, width: '60%' }} />
                  </div>
                ))}
              </div>
              <div className="sk" style={{ height: 120, borderRadius: 8 }} />
            </div>
          ) : report ? (
            <>
              <div className="stats" style={{ marginBottom: 20 }}>
                <StatCard label="Buyurtmalar" value={String(report.summary.totalOrders)} color="#3b82f6" icon="📦" />
                <StatCard label="Yetkazilgan" value={String(report.summary.delivered)} color="#16a34a" icon="✅" />
                <StatCard label="Bekor qilingan" value={String(report.summary.cancelled)} color="#dc2626" icon="❌" />
                <StatCard label="Aylanma" value={formatSom(report.summary.revenue)} color="#16a34a" icon="💰" />
                <StatCard label="Foyda" value={formatSom(report.summary.profit)} color="#0891b2" icon="📈" />
                <StatCard label="O'rtacha chek" value={formatSom(report.summary.avgOrder)} color="#8b5cf6" icon="🧾" />
              </div>

              {/* Vertical breakdown */}
              {report.byVertical && (
                <div style={{ marginBottom: 20 }}>
                  <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: 10 }}>
                    Yo'nalish bo'yicha
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 12 }}>
                    <VerticalCard icon="🍽️" label="Ovqat" revenue={report.byVertical.food.revenue} profit={report.byVertical.food.profit} color="#ea580c" />
                    <VerticalCard icon="🚕" label="Taksi" revenue={report.byVertical.taxi.revenue} profit={report.byVertical.taxi.profit} color="#d97706" />
                    <VerticalCard icon="📦" label="Dostavka" revenue={report.byVertical.parcel.revenue} profit={report.byVertical.parcel.profit} color="#3b82f6" />
                  </div>
                </div>
              )}

              {report.daily.length > 1 && <DailyChart report={report} />}
            </>
          ) : null}
        </div>
      </div>

      {/* Status breakdown */}
      {stats && Object.keys(stats.byStatus).length > 0 && (
        <div className="card">
          <div className="card-header">
            <span className="card-title">Holat bo'yicha</span>
          </div>
          <div className="card-body">
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {Object.entries(stats.byStatus).map(([status, count]) => (
                <span
                  key={status}
                  className="badge"
                  style={{ background: statusColor(status), fontSize: 12.5, padding: '5px 12px' }}
                >
                  {statusLabel(status)}: {count}
                </span>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

/* ---- Helpers ---- */
function StatCard({
  label, value, color, icon,
}: { label: string; value: string; color: string; icon: string }) {
  return (
    <div className="stat-card">
      <div className="stat-label">
        <span>{icon}</span>
        {label}
      </div>
      <div className="stat-value" style={{ color }}>{value}</div>
    </div>
  );
}

function VerticalCard({
  icon, label, revenue, profit, color,
}: { icon: string; label: string; revenue: number; profit: number; color: string }) {
  return (
    <div
      style={{
        background: 'var(--surface-2)',
        border: '1px solid var(--border)',
        borderRadius: 10,
        padding: '14px 16px',
        borderLeft: `3px solid ${color}`,
      }}
    >
      <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-2)', marginBottom: 8 }}>
        {icon} {label}
      </div>
      <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--text)' }}>{formatSom(revenue)}</div>
      <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 3 }}>
        Foyda: {formatSom(profit)}
      </div>
    </div>
  );
}

function DailyChart({ report }: { report: Report }) {
  const max = Math.max(1, ...report.daily.map((d) => d.orders));
  return (
    <div>
      <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '0.4px', marginBottom: 14 }}>
        Kunlik buyurtmalar
      </div>
      <div
        style={{
          display: 'flex',
          alignItems: 'flex-end',
          gap: 4,
          height: 130,
          padding: '0 0 24px',
          position: 'relative',
        }}
      >
        {report.daily.map((d) => {
          const h = (d.orders / max) * 100;
          return (
            <div
              key={d.date}
              title={`${d.date}: ${d.orders} ta · ${formatSom(d.revenue)}`}
              style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, height: '100%', justifyContent: 'flex-end' }}
            >
              <div style={{ fontSize: 10, color: 'var(--text-muted)', fontWeight: 600 }}>
                {d.orders > 0 ? d.orders : ''}
              </div>
              <div
                style={{
                  width: '100%',
                  height: `${h}%`,
                  minHeight: d.orders > 0 ? 4 : 0,
                  background: 'var(--primary)',
                  borderRadius: '4px 4px 0 0',
                  opacity: 0.85,
                  transition: 'height 0.3s ease',
                }}
              />
              <div
                style={{
                  fontSize: 9.5,
                  color: 'var(--text-muted)',
                  position: 'absolute',
                  bottom: 0,
                  transform: 'rotate(-40deg) translateX(-4px)',
                  transformOrigin: 'center',
                  whiteSpace: 'nowrap',
                  lineHeight: 1,
                }}
              >
                {d.date.slice(5)}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
