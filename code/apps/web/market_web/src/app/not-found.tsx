import Link from 'next/link';

export default function NotFound() {
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
          <div className="empty-icon">🔍</div>
          <div className="empty-title">Sahifa topilmadi</div>
          <div className="empty-desc">Bu havola eskirgan yoki noto&apos;g&apos;ri bo&apos;lishi mumkin</div>
          <Link href="/" className="btn" style={{ marginTop: 18, textDecoration: 'none', display: 'inline-flex' }}>
            🏠 Bosh sahifaga
          </Link>
        </div>
      </div>
    </>
  );
}
