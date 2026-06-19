'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

export default function TabNav({ id }: { id: string }) {
  const pathname = usePathname();
  const tabs = [
    { href: `/restaurants/${id}/orders`, label: 'Buyurtmalar' },
    { href: `/restaurants/${id}/menu`, label: 'Menyu' },
  ];
  return (
    <div className="tabs">
      {tabs.map((t) => (
        <Link
          key={t.href}
          href={t.href}
          className={`tab ${pathname === t.href ? 'active' : ''}`}
        >
          {t.label}
        </Link>
      ))}
    </div>
  );
}
