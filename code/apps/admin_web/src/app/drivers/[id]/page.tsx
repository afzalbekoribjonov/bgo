'use client';

import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import {
  getDriver,
  regenerateDriverCode,
  updateDriver,
} from '@/lib/api';
import type { AdminDriver } from '@/lib/types';

export default function DriverDetailPage() {
  const params = useParams<{ id: string }>();
  const id = params.id;

  const [d, setD] = useState<AdminDriver | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [savedMsg, setSavedMsg] = useState(false);

  const [fullName, setFullName] = useState('');
  const [age, setAge] = useState('');
  const [carName, setCarName] = useState('');
  const [carYear, setCarYear] = useState('');
  const [plateNumber, setPlateNumber] = useState('');
  const [licenseInfo, setLicenseInfo] = useState('');
  const [isActive, setIsActive] = useState(true);

  const fill = useCallback((x: AdminDriver) => {
    setFullName(x.fullName);
    setAge(x.age != null ? String(x.age) : '');
    setCarName(x.carName ?? '');
    setCarYear(x.carYear != null ? String(x.carYear) : '');
    setPlateNumber(x.plateNumber ?? '');
    setLicenseInfo(x.licenseInfo ?? '');
    setIsActive(x.isActive);
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const x = await getDriver(id);
      setD(x);
      fill(x);
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, [id, fill]);

  useEffect(() => {
    load();
  }, [load]);

  async function save() {
    setSaving(true);
    setError(null);
    try {
      const x = await updateDriver(id, {
        fullName: fullName.trim(),
        age: age ? parseInt(age, 10) : undefined,
        carName: carName.trim() || undefined,
        carYear: carYear ? parseInt(carYear, 10) : undefined,
        plateNumber: plateNumber.trim() || undefined,
        licenseInfo: licenseInfo.trim() || undefined,
        isActive,
      });
      setD(x);
      fill(x);
      setSavedMsg(true);
      setTimeout(() => setSavedMsg(false), 2500);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function regenerate() {
    if (
      !window.confirm(
        'Yangi 8 xonali kod yaratilsinmi? Eski kod ishlamay qoladi.',
      )
    )
      return;
    try {
      const x = await regenerateDriverCode(id);
      setD(x);
      window.alert(`Yangi kirish kodi: ${x.loginCode}`);
    } catch (e) {
      setError((e as Error).message);
    }
  }

  if (loading) {
    return (
      <div className="container">
        <p className="muted">Yuklanmoqda…</p>
      </div>
    );
  }
  if (!d) {
    return (
      <div className="container">
        <Link href="/drivers" className="btn ghost">
          ← Haydovchilar
        </Link>
        <p className="error" style={{ marginTop: 12 }}>
          Haydovchi topilmadi
        </p>
      </div>
    );
  }

  return (
    <div className="container">
      <Link href="/drivers" className="btn ghost" style={{ marginBottom: 12 }}>
        ← Haydovchilar ro&apos;yxati
      </Link>
      <h1 className="h1" style={{ marginTop: 8 }}>
        {d.fullName} {d.isOnline ? '🟢' : '⚪'}
      </h1>
      {error && <p className="error">{error}</p>}
      {savedMsg && (
        <p style={{ color: 'var(--green)', fontWeight: 600 }}>✓ Saqlandi</p>
      )}

      {/* Kirish kodi */}
      <div
        className="card"
        style={{
          marginBottom: 16,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 10,
        }}
      >
        <div>
          <div className="muted" style={{ fontSize: 13 }}>
            Ilovaga kirish kodi (8 xonali)
          </div>
          <strong
            style={{ fontSize: 30, letterSpacing: 4, fontFamily: 'monospace' }}
          >
            {d.loginCode}
          </strong>
          <div className="muted" style={{ fontSize: 12 }}>
            Telefon: {d.phone}
          </div>
        </div>
        <button className="btn ghost" onClick={regenerate}>
          ↻ Kodni qayta yaratish
        </button>
      </div>

      {/* Ma'lumotlar */}
      <div className="card">
        <strong>Ma&apos;lumotlar</strong>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: 12,
            marginTop: 12,
          }}
        >
          <div>
            <label>F.I.SH</label>
            <input value={fullName} onChange={(e) => setFullName(e.target.value)} />
          </div>
          <div>
            <label>Yoshi</label>
            <input value={age} inputMode="numeric" onChange={(e) => setAge(e.target.value.replace(/[^0-9]/g, ''))} />
          </div>
          <div>
            <label>Avtomobil nomi</label>
            <input value={carName} onChange={(e) => setCarName(e.target.value)} />
          </div>
          <div>
            <label>Avtomobil yili</label>
            <input value={carYear} inputMode="numeric" onChange={(e) => setCarYear(e.target.value.replace(/[^0-9]/g, ''))} />
          </div>
          <div>
            <label>Davlat raqami</label>
            <input value={plateNumber} onChange={(e) => setPlateNumber(e.target.value)} />
          </div>
          <div style={{ gridColumn: '1 / -1' }}>
            <label>Guvohnoma ma‘lumotlari</label>
            <input value={licenseInfo} onChange={(e) => setLicenseInfo(e.target.value)} />
          </div>
          <div>
            <label>Holati</label>
            <button
              className={`btn ${isActive ? 'green' : 'red'}`}
              onClick={() => setIsActive((v) => !v)}
              style={{ width: '100%' }}
            >
              {isActive ? '✅ Faol' : '⛔ Bloklangan'}
            </button>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 14, alignItems: 'center' }}>
          <button className="btn" disabled={saving} onClick={save}>
            {saving ? 'Saqlanmoqda…' : 'Saqlash'}
          </button>
          <span className="muted" style={{ fontSize: 13 }}>
            {d.isOnline ? 'Hozir liniyada' : 'Hozir oflayn'}
          </span>
        </div>
      </div>
    </div>
  );
}
