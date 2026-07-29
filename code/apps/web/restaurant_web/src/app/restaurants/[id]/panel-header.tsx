'use client';

import { useRestaurant } from './restaurant-provider';
import { clearToken } from '@/lib/auth';

export default function PanelHeader() {
  const { restaurant: r, busy, toggle } = useRestaurant();

  function logout() {
    clearToken();
    window.location.href = '/';
  }

  return (
    <div className="appbar">
      <div style={{ flex: 1, overflow: 'hidden' }}>
        <div className="appbar-title">{r?.name ?? 'Oshxona paneli'}</div>
        {r && (
          <div
            className="appbar-sub"
            style={{ color: r.isOpen ? 'var(--green)' : 'var(--muted)' }}
          >
            {r.isOpen ? '● Ochiq' : '● Yopiq'}
          </div>
        )}
      </div>

      <div
        className="toggle"
        onClick={toggle}
        role="button"
        aria-label="Ochiq/yopiq"
        style={{ opacity: busy ? 0.6 : 1, pointerEvents: busy ? 'none' : 'auto' }}
      >
        <span className={`toggle-track ${r?.isOpen ? 'on' : ''}`}>
          <span className="toggle-knob" />
        </span>
      </div>

      <button className="btn ghost sm" onClick={logout} style={{ flexShrink: 0 }}>
        Chiqish
      </button>
    </div>
  );
}
