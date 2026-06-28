'use client';

import Link from 'next/link';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { createDriver, getDrivers } from '@/lib/api';
import type { AdminDriver } from '@/lib/types';

export default function DriversPage() {
  const [drivers, setDrivers] = useState<AdminDriver[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);

  const [query, setQuery] = useState('');
  const [showCreate, setShowCreate] = useState(false);

  // Forma maydonlari
  const [phone, setPhone] = useState('+998');
  const [fullName, setFullName] = useState('');
  const [age, setAge] = useState('');
  const [carName, setCarName] = useState('');
  const [carYear, setCarYear] = useState('');
  const [plateNumber, setPlateNumber] = useState('');
  const [licenseInfo, setLicenseInfo] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setDrivers(await getDrivers());
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function add() {
    if (!phone.trim() || !fullName.trim()) return;
    setBusy(true);
    setError(null);
    try {
      const created = await createDriver({
        phone: phone.trim(),
        fullName: fullName.trim(),
        age: age ? parseInt(age, 10) : undefined,
        carName: carName.trim() || undefined,
        carYear: carYear ? parseInt(carYear, 10) : undefined,
        plateNumber: plateNumber.trim() || undefined,
        licenseInfo: licenseInfo.trim() || undefined,
      });
      setPhone('+998');
      setFullName('');
      setAge('');
      setCarName('');
      setCarYear('');
      setPlateNumber('');
      setLicenseInfo('');
      setShowCreate(false);
      await load();
      window.alert(
        `Haydovchi qo'shildi.\n\nKirish kodi: ${created.loginCode}\n\nShu 8 xonali kodni haydovchiga bering — u ilovaga shu kod bilan kiradi.`,
      );
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return drivers;
    return drivers.filter(
      (d) =>
        d.fullName.toLowerCase().includes(q) ||
        d.phone.includes(q) ||
        (d.plateNumber ?? '').toLowerCase().includes(q),
    );
  }, [drivers, query]);

  const stats = useMemo(() => {
    const active = drivers.filter((d) => d.isActive).length;
    const online = drivers.filter((d) => d.isOnline).length;
    return { total: drivers.length, active, online };
  }, [drivers]);

  return (
    <div className="container">
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 8,
        }}
      >
        <h1 className="h1" style={{ marginBottom: 0 }}>
          Haydovchilar
        </h1>
        <button className="btn" onClick={() => setShowCreate((v) => !v)}>
          {showCreate ? '✕ Yopish' : '+ Yangi haydovchi'}
        </button>
      </div>

      {error && (
        <p className="error" style={{ marginTop: 12 }}>
          {error}
        </p>
      )}

      <div className="stats" style={{ marginTop: 16 }}>
        <div className="stat">
          <div className="muted">Jami</div>
          <strong style={{ fontSize: 24 }}>{stats.total}</strong>
        </div>
        <div className="stat">
          <div className="muted">Faol</div>
          <strong style={{ fontSize: 24, color: 'var(--green)' }}>
            {stats.active}
          </strong>
        </div>
        <div className="stat">
          <div className="muted">Hozir liniyada</div>
          <strong style={{ fontSize: 24, color: 'var(--blue)' }}>
            {stats.online}
          </strong>
        </div>
      </div>

      {showCreate && (
        <div className="card" style={{ marginBottom: 16 }}>
          <strong>Yangi haydovchi qo‘shish</strong>
          <p className="muted" style={{ fontSize: 13, margin: '4px 0 10px' }}>
            Haydovchi telefon raqami orqali bog‘lanadi. Saqlangach 8 xonali kirish
            kodi yaratiladi.
          </p>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
              gap: 10,
            }}
          >
            <div>
              <label>Telefon *</label>
              <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+99890..." />
            </div>
            <div>
              <label>F.I.SH *</label>
              <input value={fullName} onChange={(e) => setFullName(e.target.value)} placeholder="Aliyev Vali" />
            </div>
            <div>
              <label>Yoshi</label>
              <input value={age} inputMode="numeric" onChange={(e) => setAge(e.target.value.replace(/[^0-9]/g, ''))} />
            </div>
            <div>
              <label>Avtomobil nomi</label>
              <input value={carName} onChange={(e) => setCarName(e.target.value)} placeholder="Chevrolet Cobalt" />
            </div>
            <div>
              <label>Avtomobil yili</label>
              <input value={carYear} inputMode="numeric" onChange={(e) => setCarYear(e.target.value.replace(/[^0-9]/g, ''))} placeholder="2021" />
            </div>
            <div>
              <label>Davlat raqami</label>
              <input value={plateNumber} onChange={(e) => setPlateNumber(e.target.value)} placeholder="01A123BC" />
            </div>
            <div style={{ gridColumn: '1 / -1' }}>
              <label>Guvohnoma ma‘lumotlari</label>
              <input value={licenseInfo} onChange={(e) => setLicenseInfo(e.target.value)} placeholder="Seriya/raqam, amal qilish muddati..." />
            </div>
          </div>
          <button className="btn" disabled={busy} onClick={add} style={{ marginTop: 12 }}>
            {busy ? 'Saqlanmoqda…' : "Qo'shish"}
          </button>
        </div>
      )}

      <div style={{ marginBottom: 12 }}>
        <label>Qidiruv</label>
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="F.I.SH, telefon yoki davlat raqami…"
        />
      </div>

      {loading && <p className="muted">Yuklanmoqda…</p>}
      {!loading && filtered.length === 0 && !error && (
        <p className="empty">Haydovchi topilmadi</p>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {filtered.map((d) => (
          <Link
            key={d.id}
            href={`/drivers/${d.id}`}
            className="card"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 12,
              textDecoration: 'none',
              color: 'inherit',
              cursor: 'pointer',
            }}
          >
            <span
              style={{ fontSize: 16 }}
              title={d.isOnline ? 'Liniyada' : 'Oflayn'}
            >
              {d.isOnline ? '🟢' : '⚪'}
            </span>
            <div style={{ flex: 1, minWidth: 0 }}>
              <strong style={{ fontSize: 16 }}>{d.fullName}</strong>
              <div
                className="muted"
                style={{
                  fontSize: 13,
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}
              >
                📞 {d.phone}
                {d.carName ? ` · 🚗 ${d.carName}` : ''}
                {d.plateNumber ? ` (${d.plateNumber})` : ''}
              </div>
            </div>
            <span
              className="badge"
              style={{
                background: d.isActive ? 'var(--green)' : 'var(--red)',
                whiteSpace: 'nowrap',
              }}
            >
              {d.isActive ? 'Faol' : 'Bloklangan'}
            </span>
            <span style={{ color: 'var(--muted)' }}>›</span>
          </Link>
        ))}
      </div>
    </div>
  );
}
