'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const ITEMS = [
  { href: '/', icon: '📦', label: 'Mahsulotlarim' },
  { href: '/chats', icon: '💬', label: 'Suhbatlar' },
  { href: '/profile', icon: '👤', label: 'Profil' },
];

export default function BottomNav() {
  const pathname = usePathname();

  function isActive(href: string) {
    if (href === '/') return pathname === '/';
    return pathname.startsWith(href);
  }

  return (
    <nav className="bottom-nav">
      {ITEMS.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          className={`bottom-nav-item ${isActive(item.href) ? 'active' : ''}`}
        >
          <span className="icon">{item.icon}</span>
          {item.label}
        </Link>
      ))}
    </nav>
  );
}
