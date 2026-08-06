'use client';

import type { MouseEvent, ReactNode } from 'react';
import Link from 'next/link';

declare global {
  interface Window {
    /** customer_app'ning AppWebViewScreen'i ro'yxatdan o'tkazgan JS bridge. */
    NativeApp?: { postMessage: (message: string) => void };
  }
}

/**
 * market_web ilova (native WebView) ichida ochilganda "Uy" tugmasi bosilsa,
 * market sahifalari tarixini bosib chiqmasdan to'g'ridan-to'g'ri customer_app'ning
 * asosiy ekraniga qaytaradi. Bridge yo'q (oddiy brauzer) bo'lsa — <Link> o'zi
 * market_web'ning bosh sahifasiga o'tkazadi.
 */
function goNativeHome(e: MouseEvent<HTMLAnchorElement>) {
  if (typeof window !== 'undefined' && window.NativeApp) {
    e.preventDefault();
    window.NativeApp.postMessage('home');
  }
}

interface TopbarProps {
  title: ReactNode;
  /** Faqat bosh sahifada — gradient "brand-logo" belgisi title oldida. */
  brandIcon?: string;
  showBack?: boolean;
  onBack?: () => void;
}

export default function Topbar({ title, brandIcon, showBack, onBack }: TopbarProps) {
  return (
    <div className="topbar">
      {showBack && (
        <button className="topbar-back" onClick={onBack} aria-label="Orqaga">
          ←
        </button>
      )}
      <span className="topbar-title">
        {brandIcon && <span className="brand-logo">{brandIcon}</span>}
        {title}
      </span>
      <Link
        href="/"
        className="icon-btn"
        onClick={goNativeHome}
        aria-label="Ilovaning asosiy ekraniga qaytish"
        title="Bosh sahifa"
      >
        🏠
      </Link>
    </div>
  );
}
