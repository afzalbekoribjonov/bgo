import type { Metadata } from 'next';
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
        {children}
      </body>
    </html>
  );
}
