'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { formatSom, getYearReport } from '@/lib/api';
import { useToast } from '@/components/toast';
import type { MonthlyRow, YearReport } from '@/lib/types';

const MONTH_NAMES = [
  'Yanvar',
  'Fevral',
  'Mart',
  'Aprel',
  'May',
  'Iyun',
  'Iyul',
  'Avgust',
  'Sentyabr',
  'Oktyabr',
  'Noyabr',
  'Dekabr',
];
const MONTH_SHORT = ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn', 'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];

/** Platforma ishga tushgan yil — undan oldingi yillarni tanlashga hojat yo'q. */
const FIRST_YEAR = 2025;

type Metric = 'revenue' | 'profit' | 'orders';
const METRIC_LABEL: Record<Metric, string> = {
  revenue: 'Tushum',
  profit: 'Foyda',
  orders: 'Buyurtmalar',
};
const METRIC_COLOR: Record<Metric, string> = {
  revenue: 'var(--primary)',
  profit: 'var(--green)',
  orders: 'var(--amber)',
};

function metricValue(m: MonthlyRow, metric: Metric): number {
  return metric === 'orders' ? m.orders : metric === 'profit' ? m.profit : m.revenue;
}

function formatMetric(value: number, metric: Metric): string {
  return metric === 'orders' ? `${value} ta` : formatSom(value);
}

/** Foizli o'zgarish (oldingi oyga nisbatan). `null` — solishtirib bo'lmaydi. */
function deltaPercent(current: number, previous: number): number | null {
  if (previous === 0) return current === 0 ? 0 : null;
  return Math.round(((current - previous) / previous) * 100);
}

function DeltaBadge({ value }: { value: number | null }) {
  if (value === null) {
    return <span style={{ fontSize: 11.5, color: 'var(--text-muted)' }}>yangi</span>;
  }
  const up = value > 0;
  const flat = value === 0;
  return (
    <span
      style={{
        fontSize: 11.5,
        fontWeight: 700,
        color: flat ? 'var(--text-muted)' : up ? 'var(--green)' : 'var(--red)',
        whiteSpace: 'nowrap',
      }}
    >
      {flat ? '—' : `${up ? '▲' : '▼'} ${Math.abs(value)}%`}
    </span>
  );
}

/** 12 oylik ustunli diagramma — tanlangan ko'rsatkich bo'yicha. */
function YearChart({
  months,
  metric,
  selected,
  onSelect,
}: {
  months: MonthlyRow[];
  metric: Metric;
  selected: number | null;
  onSelect: (month: number | null) => void;
}) {
  const max = Math.max(1, ...months.map((m) => metricValue(m, metric)));
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 190, padding: '8px 0 26px', position: 'relative' }}>
      {months.map((m) => {
        const v = metricValue(m, metric);
        const h = (v / max) * 100;
        const active = selected === m.month;
        return (
          <button
            key={m.month}
            onClick={() => onSelect(active ? null : m.month)}
            title={`${MONTH_NAMES[m.month - 1]}: ${formatMetric(v, metric)}`}
            aria-label={`${MONTH_NAMES[m.month - 1]} — ${formatMetric(v, metric)}`}
            style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'flex-end',
              gap: 4,
              height: '100%',
              background: 'none',
              border: 'none',
              padding: 0,
              cursor: 'pointer',
            }}
          >
            <div
              style={{
                width: '100%',
                height: `${h}%`,
                minHeight: v > 0 ? 4 : 2,
                background: v > 0 ? METRIC_COLOR[metric] : 'var(--border)',
                borderRadius: '6px 6px 0 0',
                opacity: selected === null || active ? 0.9 : 0.35,
                outline: active ? `2px solid ${METRIC_COLOR[metric]}` : 'none',
                outlineOffset: 2,
                transition: 'height 0.35s ease, opacity 0.2s ease',
              }}
            />
            <div
              style={{
                position: 'absolute',
                bottom: 0,
                fontSize: 11,
                fontWeight: active ? 700 : 500,
                color: active ? 'var(--text)' : 'var(--text-muted)',
              }}
            >
              {MONTH_SHORT[m.month - 1]}
            </div>
          </button>
        );
      })}
    </div>
  );
}

function SummaryCard({ label, value, color, icon }: { label: string; value: string; color: string; icon: string }) {
  return (
    <div className="stat-card" style={{ borderLeft: `3px solid ${color}` }}>
      <div className="stat-label">
        <span>{icon}</span> {label}
      </div>
      <div className="stat-value" style={{ color }}>{value}</div>
    </div>
  );
}

export default function ReportsPage() {
  const toast = useToast();
  const thisYear = new Date().getFullYear();

  const [year, setYear] = useState(thisYear);
  const [metric, setMetric] = useState<Metric>('revenue');
  const [selectedMonth, setSelectedMonth] = useState<number | null>(null);
  const [report, setReport] = useState<YearReport | null>(null);
  const [loading, setLoading] = useState(true);

  const years = useMemo(() => {
    const out: number[] = [];
    for (let y = thisYear; y >= FIRST_YEAR; y--) out.push(y);
    return out;
  }, [thisYear]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setReport(await getYearReport(year));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [year, toast]);

  useEffect(() => { load(); }, [load]);
  // Yil almashsa tanlangan oy kontekstini yo'qotmaslik uchun tozalanadi.
  useEffect(() => { setSelectedMonth(null); }, [year]);

  const detail = report && selectedMonth
    ? {
        all: report.months[selectedMonth - 1],
        food: report.byVertical.food[selectedMonth - 1],
        taxi: report.byVertical.taxi[selectedMonth - 1],
        parcel: report.byVertical.parcel[selectedMonth - 1],
      }
    : null;

  const best = report
    ? report.months.reduce((a, b) => (metricValue(b, metric) > metricValue(a, metric) ? b : a))
    : null;

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Oylik hisobot</h1>
          <p className="page-subtitle">{year}-yil · 12 oy kesimida tushum, foyda va buyurtmalar</p>
        </div>
      </div>

      {/* Yil + ko'rsatkich tanlash */}
      <div className="card" style={{ marginBottom: 18 }}>
        <div className="card-body" style={{ paddingTop: 14, paddingBottom: 14, display: 'flex', gap: 16, flexWrap: 'wrap', alignItems: 'center' }}>
          <div className="filters" style={{ margin: 0 }}>
            {years.map((y) => (
              <button key={y} className={`chip ${year === y ? 'active' : ''}`} onClick={() => setYear(y)}>
                {y}
              </button>
            ))}
          </div>
          <div style={{ width: 1, alignSelf: 'stretch', background: 'var(--border)' }} />
          <div className="filters" style={{ margin: 0 }}>
            {(['revenue', 'profit', 'orders'] as const).map((m) => (
              <button key={m} className={`chip ${metric === m ? 'active' : ''}`} onClick={() => setMetric(m)}>
                {METRIC_LABEL[m]}
              </button>
            ))}
          </div>
        </div>
      </div>

      {loading ? (
        <>
          <div className="stats" style={{ marginBottom: 18 }}>
            {[...Array(4)].map((_, i) => (
              <div key={i} className="stat-card"><div className="sk sk-para" /></div>
            ))}
          </div>
          <div className="card"><div className="card-body"><div className="sk" style={{ height: 190, borderRadius: 10 }} /></div></div>
        </>
      ) : !report ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">📊</div>
            <div className="empty-title">Hisobotni yuklab bo&apos;lmadi</div>
            <button className="btn ghost" style={{ marginTop: 12 }} onClick={load}>Qayta urinish</button>
          </div>
        </div>
      ) : (
        <>
          {/* Yillik jamlanma */}
          <div className="stats" style={{ marginBottom: 18 }}>
            <SummaryCard label="Buyurtmalar" value={`${report.summary.totalOrders} ta`} color="var(--amber)" icon="📦" />
            <SummaryCard label="Yakunlangan" value={`${report.summary.delivered} ta`} color="var(--green)" icon="✅" />
            <SummaryCard label="Tushum" value={formatSom(report.summary.revenue)} color="var(--primary)" icon="💰" />
            <SummaryCard label="Platforma foydasi" value={formatSom(report.summary.profit)} color="var(--green)" icon="🏦" />
          </div>

          {/* Diagramma */}
          <div className="card" style={{ marginBottom: 18 }}>
            <div className="card-header">
              <span className="card-title">📈 {METRIC_LABEL[metric]} — {year}</span>
              {best && metricValue(best, metric) > 0 && (
                <span style={{ fontSize: 12.5, color: 'var(--text-muted)' }}>
                  Eng yuqori: <b style={{ color: 'var(--text)' }}>{MONTH_NAMES[best.month - 1]}</b> ·{' '}
                  {formatMetric(metricValue(best, metric), metric)}
                </span>
              )}
            </div>
            <div className="card-body">
              <YearChart months={report.months} metric={metric} selected={selectedMonth} onSelect={setSelectedMonth} />
              <div style={{ fontSize: 12, color: 'var(--text-muted)', textAlign: 'center' }}>
                Oyni bosing — o&apos;sha oyning vertikal bo&apos;yicha taqsimoti ochiladi
              </div>
            </div>
          </div>

          {/* Tanlangan oy tafsiloti */}
          {detail && (
            <div className="card" style={{ marginBottom: 18 }}>
              <div className="card-header">
                <span className="card-title">
                  🔎 {MONTH_NAMES[selectedMonth! - 1]} {year}
                </span>
                <button className="btn ghost btn-sm" onClick={() => setSelectedMonth(null)}>Yopish</button>
              </div>
              <div className="card-body">
                <div className="stats" style={{ marginBottom: 0 }}>
                  {([
                    ['🍽️ Ovqat', detail.food],
                    ['🚕 Taksi', detail.taxi],
                    ['📦 Dostavka', detail.parcel],
                  ] as const).map(([label, row]) => (
                    <div key={label} className="stat-card">
                      <div className="stat-label">{label}</div>
                      <div style={{ fontSize: 17, fontWeight: 700, color: 'var(--text)' }}>{formatSom(row.revenue)}</div>
                      <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 3 }}>
                        Foyda: {formatSom(row.profit)} · {row.delivered} ta yakunlangan
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* 12 oy jadvali */}
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Oy</th>
                  <th>Buyurtmalar</th>
                  <th>Yakunlangan</th>
                  <th>Bekor qilingan</th>
                  <th>Tushum</th>
                  <th>Foyda</th>
                  <th>O&apos;zgarish</th>
                </tr>
              </thead>
              <tbody>
                {report.months.map((m, i) => {
                  const prev = i > 0 ? report.months[i - 1] : null;
                  const empty = m.orders === 0;
                  return (
                    <tr
                      key={m.month}
                      onClick={() => setSelectedMonth(selectedMonth === m.month ? null : m.month)}
                      style={{
                        cursor: 'pointer',
                        background: selectedMonth === m.month ? 'var(--surface-2, rgba(127,127,127,0.06))' : undefined,
                        opacity: empty ? 0.55 : 1,
                      }}
                    >
                      <td style={{ fontWeight: 600, color: 'var(--text)' }}>{MONTH_NAMES[m.month - 1]}</td>
                      <td>{m.orders}</td>
                      <td style={{ color: 'var(--green)' }}>{m.delivered}</td>
                      <td style={{ color: m.cancelled > 0 ? 'var(--red)' : 'var(--text-muted)' }}>{m.cancelled}</td>
                      <td style={{ fontWeight: 600 }}>{formatSom(m.revenue)}</td>
                      <td style={{ color: 'var(--green)', fontWeight: 600 }}>{formatSom(m.profit)}</td>
                      <td>
                        {prev ? (
                          <DeltaBadge value={deltaPercent(metricValue(m, metric), metricValue(prev, metric))} />
                        ) : (
                          <span style={{ fontSize: 11.5, color: 'var(--text-muted)' }}>—</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  );
}
