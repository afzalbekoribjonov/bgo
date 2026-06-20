'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const LINKS = [
  { href: '/', label: 'Dashboard' },
  { href: '/orders', label: 'Buyurtmalar' },
  { href: '/restaurants', label: 'Oshxonalar' },
  { href: '/tariff', label: 'Tariflar' },
  { href: '/promos', label: 'Promokodlar' },
];

export default function Nav() {
  const pathname = usePathname();
  return (
    <nav className="nav">
      {LINKS.map((l) => (
        <Link
          key={l.href}
          href={l.href}
          className={pathname === l.href ? 'active' : ''}
        >
          {l.label}
        </Link>
      ))}
    </nav>
  );
}
