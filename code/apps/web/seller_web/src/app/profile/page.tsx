'use client';

import { useCallback, useEffect, useState } from 'react';
import { getProfile, updateProfile } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import { useAuthState } from '@/lib/auth-context';
import type { SellerProfile } from '@/lib/types';

const TYPE_LABEL: Record<string, string> = { SHOP: "Do'kon", CONSTRUCTION: 'Qurilish' };

export default function ProfilePage() {
  const toast = useToast();
  const dialog = useDialog();
  const { logout } = useAuthState();
  const [profile, setProfile] = useState<SellerProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [contactPhone, setContactPhone] = useState('');
  const [address, setAddress] = useState('');
  const [pin, setPin] = useState<{ lat: number; lng: number } | null>(null);
  const [locating, setLocating] = useState(false);
  const [formErr, setFormErr] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const p = await getProfile();
      setProfile(p);
      setName(p.name);
      setDescription(p.description ?? '');
      setContactPhone(p.contactPhone);
      setAddress(p.address ?? '');
      setPin(p.lat !== null && p.lng !== null ? { lat: p.lat, lng: p.lng } : null);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  /** Do'kon joylashuvini qurilma GPS'idan olish — "eng yaqin birinchi" uchun. */
  function detectLocation() {
    if (!navigator.geolocation) {
      toast('Qurilmada geolokatsiya mavjud emas', 'error');
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setPin({
          lat: parseFloat(pos.coords.latitude.toFixed(6)),
          lng: parseFloat(pos.coords.longitude.toFixed(6)),
        });
        setLocating(false);
        toast('Joylashuv aniqlandi — saqlashni unutmang', 'success');
      },
      () => {
        setLocating(false);
        toast("Joylashuvni aniqlab bo'lmadi — ruxsat bering", 'error');
      },
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  async function save() {
    setFormErr('');
    if (!name.trim()) { setFormErr('Nomni kiriting'); return; }
    if (!contactPhone.trim()) { setFormErr('Aloqa telefonini kiriting'); return; }
    setSaving(true);
    try {
      const p = await updateProfile({
        name: name.trim(),
        description: description.trim() || undefined,
        contactPhone: contactPhone.trim(),
        address: address.trim() || undefined,
        ...(pin ? { lat: pin.lat, lng: pin.lng } : {}),
      });
      setProfile(p);
      toast('Profil yangilandi', 'success');
    } catch (e) {
      setFormErr((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function doLogout() {
    const ok = await dialog.confirm('Hisobingizdan chiqmoqchimisiz?', { title: 'Chiqish' });
    if (ok) logout();
  }

  if (loading) {
    return (
      <>
        <div className="topbar"><span className="topbar-title">👤 Profil</span></div>
        <div className="content"><div className="sk sk-para" /></div>
      </>
    );
  }

  return (
    <>
      <div className="topbar">
        <span className="topbar-title">👤 Profil</span>
      </div>
      <div className="content">
        {profile && (
          <div className="hero">
            <div className="hero-title">{profile.name}</div>
            <div className="hero-sub">{TYPE_LABEL[profile.sellerType]} · {profile.isActive ? 'Faol' : 'Nofaol'}</div>
            <span className="hero-emoji">🏪</span>
          </div>
        )}

        <div className="field">
          <label>Nomi *</label>
          <input value={name} onChange={(e) => setName(e.target.value)} />
        </div>
        <div className="field">
          <label>Tavsif</label>
          <input value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Qisqa tavsif" />
        </div>
        <div className="field">
          <label>Aloqa telefoni *</label>
          <input value={contactPhone} onChange={(e) => setContactPhone(e.target.value)} placeholder="+998901234567" />
        </div>
        <div className="field">
          <label>Do'kon manzili</label>
          <input
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder="masalan: Beshariq, Mustaqillik ko'chasi 10"
          />
        </div>
        <div className="field">
          <label>Joylashuv</label>
          <div className="row" style={{ gap: 10, flexWrap: 'wrap' }}>
            <button type="button" className="btn ghost" disabled={locating} onClick={detectLocation}>
              {locating ? 'Aniqlanmoqda…' : "📍 Do'kondaman — joylashuvni aniqlash"}
            </button>
            {pin && (
              <span className="text-sm" style={{ color: 'var(--green)', fontWeight: 700 }}>
                ✓ {pin.lat.toFixed(4)}, {pin.lng.toFixed(4)}
              </span>
            )}
          </div>
          <div className="text-xs muted" style={{ marginTop: 6 }}>
            Joylashuv saqlansa — mahsulotlaringiz yaqin-atrofdagi mijozlarga birinchi ko'rsatiladi.
          </div>
        </div>
        {formErr && <div className="err-block">{formErr}</div>}
        <button className="btn btn-block" disabled={saving} onClick={save} style={{ marginBottom: 24 }}>
          {saving ? 'Saqlanmoqda…' : 'Saqlash'}
        </button>

        <div className="divider" />
        <button className="btn ghost btn-block" onClick={doLogout} style={{ color: 'var(--red)' }}>
          Chiqish
        </button>
      </div>
    </>
  );
}
