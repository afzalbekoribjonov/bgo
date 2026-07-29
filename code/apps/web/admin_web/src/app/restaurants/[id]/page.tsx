'use client';

import dynamic from 'next/dynamic';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import {
  formatSom,
  getKitchenCredential,
  getManageRestaurants,
  getRestaurantMenu,
  setKitchenCredential,
  updateRestaurant,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import { OwnerAssignModal } from '@/components/owner-assign-modal';
import type { AdminRestaurant, RestaurantMenuView } from '@/lib/types';

const LocationMap = dynamic(() => import('@/components/location-map'), {
  ssr: false,
  loading: () => (
    <div
      style={{
        height: 360,
        background: 'var(--surface-2)',
        border: '1px solid var(--border)',
        borderRadius: 10,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'var(--text-muted)',
        flexDirection: 'column',
        gap: 8,
      }}
    >
      <div className="spinner" />
      <span style={{ fontSize: 13 }}>Xarita yuklanmoqda…</span>
    </div>
  ),
});

const STATUSES = ['ACTIVE', 'PENDING', 'BLOCKED'] as const;
const STATUS_LABEL: Record<string, string> = {
  ACTIVE: 'Faol',
  PENDING: 'Kutilmoqda',
  BLOCKED: 'Bloklangan',
};

type Tab = 'info' | 'location' | 'access' | 'menu';

function TabButton({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: '10px 18px',
        border: 'none',
        borderBottom: active ? '2px solid var(--primary)' : '2px solid transparent',
        background: 'none',
        color: active ? 'var(--primary)' : 'var(--text-muted)',
        fontWeight: active ? 700 : 500,
        fontSize: 14,
        cursor: 'pointer',
        borderRadius: '6px 6px 0 0',
        transition: 'all .15s',
        whiteSpace: 'nowrap',
      }}
    >
      {children}
    </button>
  );
}

export default function RestaurantDetailPage() {
  const params = useParams<{ id: string }>();
  const id = params.id;
  const toast = useToast();

  const [tab, setTab] = useState<Tab>('info');
  const [r, setR] = useState<AdminRestaurant | null>(null);
  const [menu, setMenu] = useState<RestaurantMenuView | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [ownerModalOpen, setOwnerModalOpen] = useState(false);

  // Edit fields
  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [commission, setCommission] = useState('0');
  const [status, setStatus] = useState<AdminRestaurant['status']>('ACTIVE');
  const [isOpen, setIsOpen] = useState(true);
  const [lat, setLat] = useState(0);
  const [lng, setLng] = useState(0);

  // Kitchen credential
  const [credUsername, setCredUsername] = useState('');
  const [credPassword, setCredPassword] = useState('');
  const [credExists, setCredExists] = useState(false);
  const [credSaving, setCredSaving] = useState(false);
  const [credErr, setCredErr] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [all, m, cred] = await Promise.all([
        getManageRestaurants(),
        getRestaurantMenu(id).catch(() => null),
        getKitchenCredential(id).catch(() => null),
      ]);
      const found = all.find((x) => x.id === id) ?? null;
      setR(found);
      setMenu(m);
      if (cred) {
        setCredExists(cred.exists);
        setCredUsername(cred.username ?? '');
      }
      if (found) {
        setName(found.name);
        setAddress(found.address);
        setPhone(found.phone);
        setCommission(String(found.commissionPercent));
        setStatus(found.status);
        setIsOpen(found.isOpen);
        setLat(found.lat);
        setLng(found.lng);
      }
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { load(); }, [load]);

  async function save() {
    setSaving(true);
    try {
      await updateRestaurant(id, {
        name: name.trim(),
        address: address.trim(),
        phone: phone.trim(),
        commissionPercent: parseInt(commission, 10) || 0,
        status,
        isOpen,
        lat,
        lng,
      });
      toast('Saqlandi ✓', 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setSaving(false);
    }
  }

  async function saveCredential() {
    setCredErr(null);
    if (credUsername.trim().length < 3) {
      setCredErr("Login kamida 3 belgi bo'lsin");
      return;
    }
    if (credPassword.length < 4) {
      setCredErr("Parol kamida 4 belgi bo'lsin");
      return;
    }
    setCredSaving(true);
    try {
      await setKitchenCredential(id, credUsername.trim(), credPassword);
      setCredExists(true);
      setCredPassword('');
      toast("Kirish ma'lumoti saqlandi", 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setCredSaving(false);
    }
  }

  function handleOwnerAssigned() {
    toast('Ega biriktirildi ✓', 'success');
    load();
  }

  if (loading) {
    return (
      <div className="container">
        <div className="sk sk-title" style={{ marginBottom: 20 }} />
        {[...Array(3)].map((_, i) => (
          <div key={i} className="card" style={{ marginBottom: 16 }}>
            <div className="card-body">
              <div className="sk sk-para" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (!r) {
    return (
      <div className="container">
        <Link href="/restaurants" className="btn ghost" style={{ marginBottom: 16 }}>
          ← Oshxonalar
        </Link>
        <div className="card">
          <div className="empty">
            <div className="empty-icon">🔍</div>
            <div className="empty-title">Oshxona topilmadi</div>
          </div>
        </div>
      </div>
    );
  }

  const itemCount = menu?.categories.reduce((s, c) => s + c.items.length, 0) ?? 0;

  return (
    <div className="container">
      {/* Breadcrumb */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20 }}>
        <Link href="/restaurants" style={{ color: 'var(--text-muted)', textDecoration: 'none', fontSize: 13.5 }}>
          Oshxonalar
        </Link>
        <span style={{ color: 'var(--text-muted)' }}>›</span>
        <span style={{ fontSize: 13.5, color: 'var(--text-2)', fontWeight: 600 }}>{r.name}</span>
      </div>

      {/* Page header */}
      <div className="page-header">
        <div>
          <h1 className="page-title">{r.name}</h1>
          <div style={{ display: 'flex', gap: 10, marginTop: 6, alignItems: 'center' }}>
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 5,
                fontSize: 13,
                color: r.isOpen ? 'var(--green)' : 'var(--text-muted)',
                fontWeight: 600,
              }}
            >
              <span
                style={{
                  width: 8,
                  height: 8,
                  borderRadius: '50%',
                  background: r.isOpen ? 'var(--green)' : 'var(--text-muted)',
                  boxShadow: r.isOpen ? '0 0 6px var(--green)' : 'none',
                  display: 'inline-block',
                }}
              />
              {r.isOpen ? 'Ochiq' : 'Yopiq'}
            </span>
            <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>·</span>
            <span style={{ fontSize: 13, color: 'var(--text-3)' }}>⭐ {r.rating.toFixed(1)}</span>
            {r.ownerUserId && (
              <>
                <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>·</span>
                <span
                  style={{
                    fontSize: 13,
                    color: 'var(--text-3)',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 4,
                  }}
                >
                  👤 Ega: {r.ownerName?.trim() || (r.ownerPhone ?? `${r.ownerUserId.slice(0, 8)}…`)}
                  {r.ownerName && r.ownerPhone && (
                    <span style={{ color: 'var(--text-muted)' }}>({r.ownerPhone})</span>
                  )}
                </span>
              </>
            )}
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn ghost" onClick={() => setOwnerModalOpen(true)}>
            {r.ownerUserId ? '🔄 Egasini almashtirish' : '👤 Ega biriktirish'}
          </button>
        </div>
      </div>

      {ownerModalOpen && (
        <OwnerAssignModal
          restaurantId={id}
          restaurantName={r.name}
          onClose={() => setOwnerModalOpen(false)}
          onAssigned={handleOwnerAssigned}
        />
      )}

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 16, borderBottom: '1px solid var(--border)', overflowX: 'auto' }}>
        <TabButton active={tab === 'info'} onClick={() => setTab('info')}>📋 Ma&apos;lumotlar</TabButton>
        <TabButton active={tab === 'location'} onClick={() => setTab('location')}>📍 Joylashuv</TabButton>
        <TabButton active={tab === 'access'} onClick={() => setTab('access')}>🔐 Kirish</TabButton>
        <TabButton active={tab === 'menu'} onClick={() => setTab('menu')}>🍽️ Menyu ({itemCount})</TabButton>
      </div>

      {/* ---- TAB: Asosiy ma'lumotlar ---- */}
      {tab === 'info' && (
        <div className="card">
          <div className="card-header">
            <span className="card-title">📋 Asosiy ma&apos;lumotlar</span>
          </div>
          <div className="card-body">
            <div className="form-grid form-grid-auto" style={{ marginBottom: 16 }}>
              <div>
                <label>Nomi</label>
                <input value={name} onChange={(e) => setName(e.target.value)} />
              </div>
              <div>
                <label>Manzil (matn)</label>
                <input value={address} onChange={(e) => setAddress(e.target.value)} />
              </div>
              <div>
                <label>Telefon</label>
                <input value={phone} onChange={(e) => setPhone(e.target.value)} />
              </div>
              <div>
                <label>Komissiya %</label>
                <input
                  value={commission}
                  inputMode="numeric"
                  onChange={(e) => setCommission(e.target.value.replace(/[^0-9]/g, ''))}
                />
              </div>
              <div>
                <label>Holat</label>
                <select
                  value={status}
                  onChange={(e) => setStatus(e.target.value as AdminRestaurant['status'])}
                >
                  {STATUSES.map((s) => (
                    <option key={s} value={s}>
                      {STATUS_LABEL[s]}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label>Ish holati</label>
                <button
                  className={`btn ${isOpen ? 'green' : 'ghost'}`}
                  style={{ width: '100%', justifyContent: 'center' }}
                  onClick={() => setIsOpen((v) => !v)}
                >
                  {isOpen ? '🟢 Ochiq' : '⭕ Yopiq'}
                </button>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 10 }}>
              <button className="btn" disabled={saving} onClick={save}>
                {saving ? (
                  <>
                    <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
                    Saqlanmoqda…
                  </>
                ) : (
                  'Saqlash'
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ---- TAB: Xaritadagi joylashuv ---- */}
      {tab === 'location' && (
        <div className="card">
          <div className="card-header">
            <span className="card-title">📍 Xaritadagi joylashuv</span>
            <span style={{ fontSize: 12.5, color: 'var(--text-muted)', fontFamily: 'monospace' }}>
              {lat.toFixed(5)}, {lng.toFixed(5)}
            </span>
          </div>
          <div className="card-body" style={{ paddingTop: 8 }}>
            <p style={{ fontSize: 13, color: 'var(--text-3)', marginBottom: 12 }}>
              Xaritani bosib oshxona aniq joylashuvini belgilang — keyin &quot;Saqlash&quot;ni bosing.
            </p>
            <LocationMap
              lat={lat}
              lng={lng}
              onPick={(la, ln) => {
                setLat(la);
                setLng(ln);
              }}
            />
            <div style={{ marginTop: 12 }}>
              <button className="btn" disabled={saving} onClick={save}>
                {saving ? 'Saqlanmoqda…' : '📍 Joylashuvni saqlash'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ---- TAB: Oshxona paneli kirishi ---- */}
      {tab === 'access' && (
        <div className="card">
          <div className="card-header">
            <span className="card-title">🔐 Oshxona paneli kirishi</span>
            <span
              style={{
                fontSize: 12.5,
                fontWeight: 600,
                color: credExists ? 'var(--green)' : 'var(--text-muted)',
                display: 'flex',
                alignItems: 'center',
                gap: 5,
              }}
            >
              <span
                style={{
                  width: 7,
                  height: 7,
                  borderRadius: '50%',
                  background: credExists ? 'var(--green)' : 'var(--text-muted)',
                  display: 'inline-block',
                }}
              />
              {credExists ? 'Yaratilgan' : 'Yaratilmagan'}
            </span>
          </div>
          <div className="card-body">
            <p style={{ fontSize: 13, color: 'var(--text-3)', marginBottom: 14 }}>
              Oshxona egasi bu login/parol bilan{' '}
              <strong>oshxona.beshariq.uz</strong> sahifasidan kiradi.
            </p>
            <div className="form-grid form-grid-2" style={{ maxWidth: 500, marginBottom: 14 }}>
              <div>
                <label>Login</label>
                <input
                  value={credUsername}
                  autoComplete="off"
                  placeholder="masalan: milano_kitchen"
                  onChange={(e) => setCredUsername(e.target.value.replace(/\s/g, ''))}
                />
              </div>
              <div>
                <label>{credExists ? 'Yangi parol' : 'Parol'}</label>
                <input
                  value={credPassword}
                  type="text"
                  autoComplete="off"
                  placeholder={credExists ? '••••• (yangilash uchun)' : 'kamida 4 belgi'}
                  onChange={(e) => setCredPassword(e.target.value)}
                />
              </div>
            </div>
            {credErr && (
              <div className="err-block" style={{ marginBottom: 12, maxWidth: 500 }}>{credErr}</div>
            )}
            <button className="btn" disabled={credSaving} onClick={saveCredential}>
              {credSaving
                ? 'Saqlanmoqda…'
                : credExists
                ? '🔄 Parolni yangilash'
                : '🔐 Kirish yaratish'}
            </button>
          </div>
        </div>
      )}

      {/* ---- TAB: Menyu ---- */}
      {tab === 'menu' && (
        <div className="card">
          <div className="card-header">
            <span className="card-title">🍽️ Menyu</span>
            <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>
              {menu?.categories.length ?? 0} bo&apos;lim · {itemCount} taom
            </span>
          </div>
          <div className="card-body">
            {!menu || menu.categories.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '32px 0', color: 'var(--text-muted)' }}>
                <div style={{ fontSize: 28, marginBottom: 8 }}>🍽️</div>
                <div style={{ fontSize: 13.5 }}>
                  Menyu bo&apos;sh. Taomlar oshxona egasi panelida qo&apos;shiladi.
                </div>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                {menu.categories.map((c) => (
                  <div key={c.id}>
                    <div
                      style={{
                        fontWeight: 700,
                        marginBottom: 8,
                        fontSize: 14,
                        color: 'var(--text)',
                        display: 'flex',
                        alignItems: 'center',
                        gap: 8,
                      }}
                    >
                      <span
                        style={{
                          width: 3,
                          height: 16,
                          background: 'var(--primary)',
                          borderRadius: 2,
                          display: 'inline-block',
                        }}
                      />
                      {c.name}
                      <span style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 400 }}>
                        {c.items.length} taom
                      </span>
                    </div>
                    {c.items.map((it) => (
                      <div
                        key={it.id}
                        style={{
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'center',
                          padding: '9px 0',
                          borderBottom: '1px solid var(--border)',
                          opacity: it.isAvailable ? 1 : 0.45,
                        }}
                      >
                        <span style={{ fontSize: 13.5, color: 'var(--text-2)' }}>
                          {it.name}
                          {!it.isAvailable && (
                            <span
                              style={{
                                marginLeft: 8,
                                fontSize: 11.5,
                                color: 'var(--red)',
                                fontWeight: 600,
                              }}
                            >
                              (mavjud emas)
                            </span>
                          )}
                        </span>
                        <span style={{ fontWeight: 700, color: 'var(--text)', fontSize: 13.5 }}>
                          {formatSom(it.price)}
                        </span>
                      </div>
                    ))}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
