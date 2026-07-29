'use client';

import { useCallback, useEffect, useState } from 'react';
import { formatSom, getKitchenStats } from '@/lib/api';
import type { KitchenStats } from '@/lib/types';

function StatCard({
  value,
  label,
  accent,
}: {
  value: string;
  label: string;
  accent?: string;
}) {
  return (
    <div className="stat">
      <div
        className="stat-val"
        style={{ color: accent ?? 'var(--text)', fontSize: 22 }}
      >
        {value}
      </div>
      <div className="stat-lbl">{label}</div>
    </div>
  );
}

const DAY_NAMES = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sha', 'Ya'];

export default function IncomePage({ params }: { params: { id: string } }) {
  const rid = params.id;
  const [stats, setStats] = useState<KitchenStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setStats(await getKitchenStats(rid));
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, [rid]);

  useEffect(() => {
    load();
  }, [load]);

  if (loading) {
    return (
      <div className="container">
        <p className="muted" style={{ textAlign: 'center', padding: '48px 0' }}>
          Yuklanmoqda…
        </p>
      </div>
    );
  }

  if (error || !stats) {
    return (
      <div className="container">
        <div
          style={{
            background: 'rgba(224,49,49,0.07)',
            border: '1px solid rgba(224,49,49,0.3)',
            borderRadius: 12,
            padding: '12px 14px',
            color: 'var(--red)',
            fontWeight: 700,
            fontSize: 14,
          }}
        >
          ⚠ {error ?? 'Xatolik'}
        </div>
      </div>
    );
  }

  const maxRev = Math.max(...stats.weekly.map((w) => w.revenue), 1);

  return (
    <div className="container" style={{ paddingBottom: 32 }}>
      <div className="row" style={{ marginBottom: 16, marginTop: 4 }}>
        <h2 className="big">Daromad</h2>
        <button className="btn ghost sm" onClick={load}>
          ↻ Yangilash
        </button>
      </div>

      {/* Bugun */}
      <div className="card" style={{ marginBottom: 16 }}>
        <div className="sec-title" style={{ marginBottom: 12 }}>
          Bugun
        </div>
        <div className="stat-grid">
          <StatCard
            value={formatSom(stats.todayRevenue)}
            label="Daromad"
            accent="var(--primary)"
          />
          <StatCard
            value={String(stats.todayDelivered)}
            label="Yetkazildi"
            accent="var(--green)"
          />
          <StatCard
            value={String(stats.todayOrders)}
            label="Jami buyurtma"
          />
          <StatCard
            value={String(stats.cancelledToday)}
            label="Bekor qilindi"
            accent={stats.cancelledToday > 0 ? 'var(--red)' : undefined}
          />
        </div>
      </div>

      {/* Jami */}
      <div className="card" style={{ marginBottom: 16 }}>
        <div className="sec-title" style={{ marginBottom: 12 }}>
          Jami barcha vaqt
        </div>
        <div className="stat-grid">
          <StatCard
            value={formatSom(stats.totalRevenue)}
            label="Umumiy daromad"
            accent="var(--primary)"
          />
          <StatCard
            value={String(stats.totalDelivered)}
            label="Yetkazildi"
            accent="var(--green)"
          />
          <StatCard
            value={String(stats.totalOrders)}
            label="Jami buyurtma"
          />
          <StatCard
            value={formatSom(stats.avgOrderValue)}
            label="O'rtacha buyurtma"
          />
        </div>
      </div>

      {/* Haftalik grafik */}
      <div className="card">
        <div className="sec-title" style={{ marginBottom: 16 }}>
          Oxirgi 7 kun (daromad)
        </div>

        {stats.weekly.every((w) => w.revenue === 0) ? (
          <p className="muted" style={{ textAlign: 'center', padding: '16px 0' }}>
            Bu haftada hali yetkazilgan buyurtma yo&apos;q
          </p>
        ) : (
          <div
            style={{
              display: 'flex',
              alignItems: 'flex-end',
              gap: 8,
              height: 140,
              paddingBottom: 24,
            }}
          >
            {stats.weekly.map((w, i) => {
              const ratio = w.revenue / maxRev;
              const barH = Math.max(ratio * 110, w.revenue > 0 ? 6 : 2);
              const dayOfWeek = new Date(w.date).getDay(); // 0=Sun
              const label = DAY_NAMES[(dayOfWeek + 6) % 7]; // Mo=0
              const isToday = w.date === new Date().toISOString().slice(0, 10);
              return (
                <div
                  key={i}
                  style={{
                    flex: 1,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: 4,
                    position: 'relative',
                  }}
                  title={`${w.date}: ${formatSom(w.revenue)} (${w.orders} ta)`}
                >
                  <div
                    style={{
                      width: '100%',
                      maxWidth: 40,
                      height: barH,
                      background: isToday
                        ? 'var(--primary)'
                        : 'var(--border)',
                      borderRadius: '6px 6px 0 0',
                      transition: 'height 0.3s',
                      minHeight: 2,
                    }}
                  />
                  <div
                    style={{
                      position: 'absolute',
                      bottom: 0,
                      fontSize: 11,
                      color: isToday ? 'var(--primary)' : 'var(--muted)',
                      fontWeight: isToday ? 800 : 600,
                    }}
                  >
                    {label}
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Legend */}
        <div
          style={{
            display: 'flex',
            gap: 16,
            marginTop: 8,
            flexWrap: 'wrap',
          }}
        >
          {stats.weekly.map((w, i) => (
            <div key={i} style={{ fontSize: 12, color: 'var(--muted)' }}>
              {w.date.slice(5)}: {w.orders} ta /{' '}
              <span style={{ fontWeight: 700, color: 'var(--text)' }}>
                {formatSom(w.revenue)}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
