import type { Metadata } from 'next';
import AuthGate from '@/components/auth-gate';
import Nav from './nav';
import './globals.css';

export const metadata: Metadata = {
  title: 'Beshariq — Admin',
  description: 'Beshariq Super-App boshqaruv paneli',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="uz">
      <body>
        <div className="appbar">⚙️ Beshariq — Admin panel</div>
        <AuthGate>
          <Nav />
          {children}
        </AuthGate>
      </body>
    </html>
  );
}
