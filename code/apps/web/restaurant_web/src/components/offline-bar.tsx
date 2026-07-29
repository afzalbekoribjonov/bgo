'use client';

import { useEffect, useState } from 'react';

export default function OfflineBar() {
  const [offline, setOffline] = useState(false);

  useEffect(() => {
    const handleOnline = () => setOffline(false);
    const handleOffline = () => setOffline(true);
    setOffline(!navigator.onLine);
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  if (!offline) return null;

  return (
    <div className="offline-bar" role="alert" aria-live="assertive">
      ⚠ Internet aloqasi yo&apos;q — ma&apos;lumotlar yangilanmaydi
    </div>
  );
}
