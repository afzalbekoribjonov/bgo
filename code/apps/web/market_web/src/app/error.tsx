'use client';

export default function GlobalError({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <>
      <div className="topbar">
        <span className="topbar-title">
          <span className="brand-logo">🛒</span>
          Beshariq Market
        </span>
      </div>
      <div className="content">
        <div className="empty" style={{ paddingTop: 80 }}>
          <div className="empty-icon">⚠️</div>
          <div className="empty-title">Nimadir noto&apos;g&apos;ri ketdi</div>
          <div className="empty-desc">Sahifani qayta yuklashga urinib ko&apos;ring</div>
          <button className="btn" style={{ marginTop: 18 }} onClick={reset}>
            🔄 Qayta urinish
          </button>
        </div>
      </div>
    </>
  );
}
