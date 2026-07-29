'use client';

import dynamic from 'next/dynamic';

// Xarita faqat brauzerda (SSR'siz) — maplibre window talab qiladi.
const LiveMap = dynamic(() => import('./live-map'), {
  ssr: false,
  loading: () => (
    <div
      style={{
        height: '100%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        gap: 10,
        color: 'var(--text-muted)',
        background: 'var(--surface-2)',
        borderRadius: 14,
      }}
    >
      <div className="spinner" />
      <span style={{ fontSize: 13 }}>Jonli xarita yuklanmoqda…</span>
    </div>
  ),
});

/** Jonli xarita — barcha online haydovchilar real vaqtda (admin nazorati). */
export default function LivePage() {
  return (
    <div
      className="container"
      style={{
        display: 'flex',
        flexDirection: 'column',
        height: 'calc(100vh - 48px)',
        maxWidth: 'none',
      }}
    >
      <div className="page-header" style={{ marginBottom: 14 }}>
        <div>
          <h1 className="page-title">Jonli xarita</h1>
          <p className="page-subtitle">
            Barcha online haydovchilar — real vaqtda, yo&apos;nalish bo&apos;yicha
          </p>
        </div>
      </div>
      <div style={{ flex: 1, minHeight: 0 }}>
        <LiveMap />
      </div>
    </div>
  );
}
