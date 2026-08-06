import type { Metadata, Viewport } from 'next';
import { ToastProvider } from '@/components/toast';
import { DialogProvider } from '@/components/dialog';
import { AuthProvider } from '@/lib/auth-context';
import { CartProvider } from '@/lib/cart';
import BottomNav from '@/components/bottom-nav';
import ReadyPickupBanner from '@/components/ready-pickup-banner';
import './globals.css';

export const metadata: Metadata = {
  title: 'Beshariq Market',
  description: "Beshariq Market — mahsulotlarni buyurtma qiling, yetkazib beramiz yoki olib keting",
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
              <CartProvider>
                <div className="app">
                  <ReadyPickupBanner />
                  {children}
                  <BottomNav />
                </div>
              </CartProvider>
            </AuthProvider>
          </DialogProvider>
        </ToastProvider>
      </body>
    </html>
  );
}
