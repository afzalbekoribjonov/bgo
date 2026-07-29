'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useCart } from '@/lib/cart';

const ITEMS = [
  { href: '/', icon: '🏠', label: 'Bosh sahifa' },
  { href: '/cart', icon: '🛒', label: 'Savat' },
  { href: '/orders', icon: '📦', label: 'Buyurtmalarim' },
  { href: '/support', icon: '💬', label: 'Yordam' },
];

export default function BottomNav() {
  const pathname = usePathname();
  const { count } = useCart();

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
          {item.href === '/cart' && count > 0 && <span className="badge-dot">{count}</span>}
        </Link>
      ))}
    </nav>
  );
}
