import type { Metadata } from 'next';
import AuthGate from '@/components/auth-gate';
import './globals.css';

export const metadata: Metadata = {
  title: 'Beshariq — Oshxona paneli',
  description: 'Hamkor oshxonalar uchun buyurtma va menyu boshqaruvi',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="uz">
      <body>
        <div className="appbar">🍽 Beshariq — Oshxona paneli</div>
        <AuthGate>{children}</AuthGate>
      </body>
    </html>
  );
}
