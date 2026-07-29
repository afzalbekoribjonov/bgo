import type { Metadata, Viewport } from 'next';
import { ToastProvider } from '@/components/toast';
import { DialogProvider } from '@/components/dialog';
import { AuthProvider } from '@/lib/auth-context';
import BottomNav from '@/components/bottom-nav';
import './globals.css';

export const metadata: Metadata = {
  title: "Do'konlar — Beshariq",
  description: "Do'konlar va Qurilishda foydali — mahalliy sotuvchilar mahsulotlari",
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="uz">
      <body>
        <ToastProvider>
          <DialogProvider>
            <AuthProvider>
              <div className="app">
                {children}
                <BottomNav />
              </div>
            </AuthProvider>
          </DialogProvider>
        </ToastProvider>
      </body>
    </html>
  );
}
