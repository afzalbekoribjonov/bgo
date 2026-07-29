import type { Metadata, Viewport } from 'next';
import { ToastProvider } from '@/components/toast';
import { DialogProvider } from '@/components/dialog';
import { AuthProvider } from '@/lib/auth-context';
import AuthGate from '@/components/auth-gate';
import './globals.css';

export const metadata: Metadata = {
  title: 'Sotuvchi paneli — Beshariq',
  description: "Do'konlar va Qurilishda foydali sotuvchilari uchun boshqaruv paneli",
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
              <AuthGate>{children}</AuthGate>
            </AuthProvider>
          </DialogProvider>
        </ToastProvider>
      </body>
    </html>
  );
}
