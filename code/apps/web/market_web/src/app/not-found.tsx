import Link from 'next/link';
import Topbar from '@/components/topbar';

export default function NotFound() {
  return (
    <>
      <Topbar title="Beshariq Market" brandIcon="🛒" />
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
