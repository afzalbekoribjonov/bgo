'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

/* ---- SVG Icons (Feather-style) ---- */
function IcGrid({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" rx="1.5"/>
      <rect x="14" y="3" width="7" height="7" rx="1.5"/>
      <rect x="3" y="14" width="7" height="7" rx="1.5"/>
      <rect x="14" y="14" width="7" height="7" rx="1.5"/>
    </svg>
  );
}

function IcBag({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z"/>
      <line x1="3" y1="6" x2="21" y2="6"/>
      <path d="M16 10a4 4 0 01-8 0"/>
    </svg>
  );
}

function IcStore({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
      <polyline points="9 22 9 12 15 12 15 22"/>
    </svg>
  );
}

function IcTruck({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <rect x="1" y="3" width="15" height="13" rx="1.5"/>
      <path d="M16 8h4l3 3v5h-7V8z"/>
      <circle cx="5.5" cy="18.5" r="2.5"/>
      <circle cx="18.5" cy="18.5" r="2.5"/>
    </svg>
  );
}

function IcSliders({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <line x1="4" y1="21" x2="4" y2="14"/>
      <line x1="4" y1="10" x2="4" y2="3"/>
      <line x1="12" y1="21" x2="12" y2="12"/>
      <line x1="12" y1="8" x2="12" y2="3"/>
      <line x1="20" y1="21" x2="20" y2="16"/>
      <line x1="20" y1="12" x2="20" y2="3"/>
      <line x1="1" y1="14" x2="7" y2="14"/>
      <line x1="9" y1="8" x2="15" y2="8"/>
      <line x1="17" y1="16" x2="23" y2="16"/>
    </svg>
  );
}

function IcTag({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z"/>
      <line x1="7" y1="7" x2="7.01" y2="7"/>
    </svg>
  );
}

function IcUsers({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
      <circle cx="9" cy="7" r="4"/>
      <path d="M23 21v-2a4 4 0 00-3-3.87"/>
      <path d="M16 3.13a4 4 0 010 7.75"/>
    </svg>
  );
}

function IcMap({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"/>
      <line x1="8" y1="2" x2="8" y2="18"/>
      <line x1="16" y1="6" x2="16" y2="22"/>
    </svg>
  );
}

function IcNavCar({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 11l1.5-4.5A2 2 0 018.4 5h7.2a2 2 0 011.9 1.5L19 11"/>
      <rect x="3" y="11" width="18" height="7" rx="2"/>
      <circle cx="7.5" cy="15" r="1"/>
      <circle cx="16.5" cy="15" r="1"/>
      <path d="M12 2v1"/>
    </svg>
  );
}

function IcCart({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="9" cy="21" r="1.5"/>
      <circle cx="18" cy="21" r="1.5"/>
      <path d="M2.5 3h2l2.6 12.4a2 2 0 002 1.6h8.2a2 2 0 002-1.6L21 7H6"/>
    </svg>
  );
}

function IcStorefront({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9l1.5-5A1.5 1.5 0 016 3h12a1.5 1.5 0 011.5 1l1.5 5"/>
      <path d="M3 9a2.5 2.5 0 005 0 2.5 2.5 0 005 0 2.5 2.5 0 005 0 2.5 2.5 0 005 0"/>
      <path d="M5 9v9a1.5 1.5 0 001.5 1.5H10v-5h4v5h3.5A1.5 1.5 0 0019 18V9"/>
    </svg>
  );
}

function IcChat({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/>
    </svg>
  );
}

function IcFlag({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/>
      <line x1="4" y1="22" x2="4" y2="3"/>
    </svg>
  );
}

function IcWarning({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/>
      <line x1="12" y1="9" x2="12" y2="13"/>
      <line x1="12" y1="17" x2="12.01" y2="17"/>
    </svg>
  );
}

function IcLogOut({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/>
      <polyline points="16 17 21 12 16 7"/>
      <line x1="21" y1="12" x2="9" y2="12"/>
    </svg>
  );
}

function IcChart({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="20" x2="18" y2="10"/>
      <line x1="12" y1="20" x2="12" y2="4"/>
      <line x1="6" y1="20" x2="6" y2="14"/>
    </svg>
  );
}

/* ---- Nav config ---- */
const MAIN_LINKS = [
  { href: '/', label: 'Dashboard', Icon: IcGrid },
  { href: '/live', label: 'Jonli xarita', Icon: IcNavCar },
  { href: '/orders', label: 'Buyurtmalar', Icon: IcBag },
  { href: '/reports', label: 'Oylik hisobot', Icon: IcChart },
  { href: '/restaurants', label: 'Oshxonalar', Icon: IcStore },
  { href: '/market', label: 'Market', Icon: IcCart },
  { href: '/sellers', label: 'Sotuvchilar', Icon: IcStorefront },
  { href: '/support', label: 'Yordam', Icon: IcChat },
  { href: '/drivers', label: 'Haydovchilar', Icon: IcTruck },
  { href: '/drivers/suspicious', label: 'Shubhali haydovchilar', Icon: IcWarning },
  { href: '/customers/complaints', label: "E'tirozli mijozlar", Icon: IcFlag },
];

const SETTINGS_LINKS = [
  { href: '/tariff', label: 'Tariflar', Icon: IcSliders },
  { href: '/promos', label: 'Promokodlar', Icon: IcTag },
  { href: '/partners', label: 'Hamkorlik', Icon: IcUsers },
  { href: '/geo', label: 'Hududlar', Icon: IcMap },
];

/* ---- Component ---- */
export default function Nav({ onLogout }: { onLogout: () => void }) {
  const pathname = usePathname();

  function isActive(href: string) {
    if (href === '/') return pathname === '/';
    return pathname.startsWith(href);
  }

  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <div className="sidebar-logo-mark">
          <div className="sidebar-logo-icon">🍽️</div>
          <div>
            <div className="sidebar-logo-text">Beshariq</div>
            <div className="sidebar-logo-sub">Admin</div>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="sidebar-nav">
        {/* Main */}
        <div className="sidebar-section">
          <div className="sidebar-section-label">Asosiy</div>
          {MAIN_LINKS.map(({ href, label, Icon }) => (
            <Link
              key={href}
              href={href}
              className={`sidebar-link ${isActive(href) ? 'active' : ''}`}
            >
              <Icon className="sidebar-icon" />
              {label}
            </Link>
          ))}
        </div>

        {/* Settings */}
        <div className="sidebar-section" style={{ marginTop: 8 }}>
          <div className="sidebar-section-label">Sozlamalar</div>
          {SETTINGS_LINKS.map(({ href, label, Icon }) => (
            <Link
              key={href}
              href={href}
              className={`sidebar-link ${isActive(href) ? 'active' : ''}`}
            >
              <Icon className="sidebar-icon" />
              {label}
            </Link>
          ))}
        </div>
      </nav>

      {/* Footer */}
      <div className="sidebar-footer">
        <div className="sidebar-user">
          <div className="sidebar-avatar">A</div>
          <div>
            <div className="sidebar-user-name">Admin</div>
            <div className="sidebar-user-role">Super admin</div>
          </div>
        </div>
        <button className="sidebar-link" onClick={onLogout} style={{ color: '#f87171' }}>
          <IcLogOut className="sidebar-icon" />
          Chiqish
        </button>
      </div>
    </aside>
  );
}
