import type { Metadata } from 'next';
import AuthGate from '@/components/auth-gate';
import { ToastProvider } from '@/components/toast';
import { DialogProvider } from '@/components/dialog';
import './globals.css';

export const metadata: Metadata = {
  title: 'Beshariq — Admin',
  description: 'Beshariq Super-App boshqaruv paneli',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="uz">
      <body>
        <ToastProvider>
          <DialogProvider>
            <AuthGate>{children}</AuthGate>
          </DialogProvider>
        </ToastProvider>
      </body>
    </html>
  );
}
