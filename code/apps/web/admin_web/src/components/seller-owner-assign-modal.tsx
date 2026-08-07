'use client';

import { useState } from 'react';
import { assignSellerOwnerByPhone, lookupSellerOwner } from '@/lib/api';
import type { OwnerCandidate } from '@/lib/types';

const PHONE_RE = /^\+998\d{9}$/;

type Phase = 'input' | 'searching' | 'found' | 'not-found' | 'assigning';

export function SellerOwnerAssignModal({
  sellerId,
  sellerName,
  onClose,
  onAssigned,
}: {
  sellerId: string;
  sellerName: string;
  onClose: () => void;
  onAssigned: () => void;
}) {
  const [phone, setPhone] = useState('+998');
  const [phase, setPhase] = useState<Phase>('input');
  const [candidate, setCandidate] = useState<OwnerCandidate | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const validFormat = PHONE_RE.test(phone.trim());

  async function search() {
    if (!validFormat) {
      setErr("Telefon +998XXXXXXXXX formatida bo'lsin (9 ta raqam)");
      return;
    }
    setErr(null);
    setPhase('searching');
    try {
      const found = await lookupSellerOwner(phone.trim());
      setCandidate(found);
      setPhase(found ? 'found' : 'not-found');
    } catch (e) {
      setErr((e as Error).message);
      setPhase('input');
    }
  }

  function backToSearch() {
    setCandidate(null);
    setPhase('input');
    setErr(null);
  }

  async function confirm() {
    setPhase('assigning');
    setErr(null);
    try {
      await assignSellerOwnerByPhone(sellerId, phone.trim());
      onAssigned();
      onClose();
    } catch (e) {
      setErr((e as Error).message);
      setPhase('found');
    }
  }

  return (
    <div
      className="dialog-overlay"
      onClick={onClose}
      onKeyDown={(e) => { if (e.key === 'Escape') onClose(); }}
    >
      <div className="dialog-box" onClick={(e) => e.stopPropagation()}>
        <div className="dialog-icon blue">👤</div>
        <div className="dialog-title">Egani biriktirish</div>
        <div className="dialog-msg">
          <strong>{sellerName}</strong> do&apos;koni egasining telefon raqamini
          kiriting — u avval Beshariq Go ilovasiga shu raqam bilan ro&apos;yxatdan
          o&apos;tgan bo&apos;lishi kerak.
        </div>

        <div style={{ marginBottom: 8 }}>
          <label className="dialog-input-label">Telefon raqami</label>
          <input
            value={phone}
            autoFocus
            disabled={phase === 'searching' || phase === 'assigning'}
            placeholder="+998901234567"
            onChange={(e) => {
              setPhone(e.target.value.replace(/[^\d+]/g, ''));
              if (phase !== 'input') { setPhase('input'); setCandidate(null); }
            }}
            onKeyDown={(e) => { if (e.key === 'Enter') search(); }}
            style={{ width: '100%' }}
          />
        </div>

        {err && (
          <div className="err-block" style={{ marginBottom: 14 }}>
            {err}
          </div>
        )}

        {phase === 'not-found' && !err && (
          <div className="owner-lookup-card owner-lookup-card--miss">
            <span className="owner-lookup-icon">🔍</span>
            <div>
              <div className="owner-lookup-title">Foydalanuvchi topilmadi</div>
              <div className="owner-lookup-sub">
                Bu raqam bilan hech kim Beshariq Go&apos;ga kirmagan. Avval
                do&apos;kon egasi ilovaga shu raqam bilan bir marta kirishi kerak.
              </div>
            </div>
          </div>
        )}

        {(phase === 'found' || phase === 'assigning') && candidate && (
          <div className="owner-lookup-card owner-lookup-card--hit">
            <span className="owner-lookup-avatar">
              {(candidate.fullName?.trim()?.[0] ?? '👤').toUpperCase()}
            </span>
            <div>
              <div className="owner-lookup-title">
                {candidate.fullName?.trim() || 'Ism kiritilmagan'}
              </div>
              <div className="owner-lookup-sub">📞 {candidate.phone}</div>
            </div>
            <span className="owner-lookup-check">✓</span>
          </div>
        )}

        <div className="dialog-actions" style={{ marginTop: 20 }}>
          <button className="btn ghost" onClick={onClose}>
            Bekor qilish
          </button>
          {phase === 'found' ? (
            <>
              <button className="btn ghost" onClick={backToSearch}>
                ← Boshqa raqam
              </button>
              <button className="btn" onClick={confirm}>
                ✓ Biriktirish
              </button>
            </>
          ) : (
            <button
              className="btn"
              disabled={!validFormat || phase === 'searching' || phase === 'assigning'}
              onClick={search}
            >
              {phase === 'searching' ? (
                <>
                  <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
                  Qidirilmoqda…
                </>
              ) : (
                '🔍 Qidirish'
              )}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
