'use client';

import { useCallback, useEffect, useState } from 'react';
import dynamic from 'next/dynamic';
import {
  createMarketplaceCategory,
  createMarketplaceSeller,
  deleteMarketplaceCategory,
  deleteMarketplaceSeller,
  getMarketplaceCategories,
  getMarketplaceSellers,
  getSellerCredential,
  setSellerCredential,
  updateMarketplaceCategory,
  updateMarketplaceSeller,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import { SellerOwnerAssignModal } from '@/components/seller-owner-assign-modal';
import type {
  I18nString,
  MarketplaceCategory,
  MarketplaceSeller,
  SellerType,
} from '@/lib/types';

const LocationMap = dynamic(() => import('@/components/location-map'), {
  ssr: false,
  loading: () => (
    <div
      style={{
        height: 300,
        background: 'var(--surface-2)',
        borderRadius: 12,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'var(--text-muted)',
        fontSize: 13,
      }}
    >
      Xarita yuklanmoqda…
    </div>
  ),
});

/** Beshariq markazi — joylashuv tanlanmaganda boshlang'ich nuqta. */
const DEFAULT_LAT = 40.4236;
const DEFAULT_LNG = 70.6094;

type Tab = 'sellers' | 'categories';

const TABS: { id: Tab; label: string }[] = [
  { id: 'sellers', label: 'Sotuvchilar' },
  { id: 'categories', label: 'Kategoriyalar' },
];

const TYPE_LABEL: Record<SellerType, string> = {
  SHOP: "Do'kon",
  CONSTRUCTION: 'Qurilish',
};

function localeLabel(v: I18nString): string {
  return v.uz || v.ru || v.uz_Cyrl || '';
}

export default function SellersPage() {
  const [tab, setTab] = useState<Tab>('sellers');

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Sotuvchilar</h1>
          <p className="page-subtitle">Do'konlar va Qurilishda foydali — uchinchi tomon sotuvchilar</p>
        </div>
      </div>

      <div className="section-tabs">
        {TABS.map((t) => (
          <button
            key={t.id}
            className={`section-tab ${tab === t.id ? 'active' : ''}`}
            onClick={() => setTab(t.id)}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'sellers' && <SellersTab />}
      {tab === 'categories' && <CategoriesTab />}
    </div>
  );
}

/* ============ Sotuvchilar ============ */
function SellersTab() {
  const toast = useToast();
  const dialog = useDialog();
  const [sellers, setSellers] = useState<MarketplaceSeller[]>([]);
  const [loading, setLoading] = useState(true);
  const [typeFilter, setTypeFilter] = useState<SellerType | 'all'>('all');
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<MarketplaceSeller | null>(null);
  const [busy, setBusy] = useState(false);
  const [formErr, setFormErr] = useState('');

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [contactPhone, setContactPhone] = useState('');
  const [sellerType, setSellerType] = useState<SellerType>('SHOP');
  const [isActive, setIsActive] = useState(true);

  // Joylashuv — "eng yaqin do'kon birinchi" saralash uchun
  const [address, setAddress] = useState('');
  const [pin, setPin] = useState<{ lat: number; lng: number } | null>(null);
  const [showMap, setShowMap] = useState(false);

  // Kirish ma'lumoti (login/parol)
  const [credUsername, setCredUsername] = useState('');
  const [credPassword, setCredPassword] = useState('');
  const [credExists, setCredExists] = useState(false);
  const [credSaving, setCredSaving] = useState(false);
  const [credErr, setCredErr] = useState('');

  // Egalik — mobil ilovada native panelga kirish uchun (telefon bo'yicha)
  const [showOwnerModal, setShowOwnerModal] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setSellers(
        await getMarketplaceSellers(typeFilter === 'all' ? undefined : typeFilter),
      );
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [typeFilter, toast]);

  useEffect(() => { load(); }, [load]);

  function resetForm() {
    setEditing(null);
    setName('');
    setDescription('');
    setContactPhone('');
    setSellerType('SHOP');
    setIsActive(true);
    setAddress('');
    setPin(null);
    setShowMap(false);
    setCredUsername('');
    setCredPassword('');
    setCredExists(false);
    setFormErr('');
    setCredErr('');
  }

  function openCreate() {
    resetForm();
    setShowForm(true);
  }

  async function openEdit(s: MarketplaceSeller) {
    setEditing(s);
    setName(s.name);
    setDescription(s.description ?? '');
    setContactPhone(s.contactPhone);
    setSellerType(s.sellerType);
    setIsActive(s.isActive);
    setAddress(s.address ?? '');
    setPin(s.lat !== null && s.lng !== null ? { lat: s.lat, lng: s.lng } : null);
    setShowMap(false);
    setCredUsername('');
    setCredPassword('');
    setFormErr('');
    setCredErr('');
    setShowForm(true);
    try {
      const cred = await getSellerCredential(s.id);
      setCredExists(cred.exists);
      setCredUsername(cred.username ?? '');
    } catch {
      setCredExists(false);
    }
  }

  async function save() {
    setFormErr('');
    if (!name.trim()) { setFormErr('Sotuvchi nomini kiriting'); return; }
    if (!contactPhone.trim()) { setFormErr("Aloqa telefonini kiriting"); return; }
    setBusy(true);
    try {
      const location = {
        address: address.trim() || undefined,
        ...(pin ? { lat: pin.lat, lng: pin.lng } : {}),
      };
      if (editing) {
        await updateMarketplaceSeller(editing.id, {
          name: name.trim(),
          description: description.trim() || undefined,
          contactPhone: contactPhone.trim(),
          ...location,
          isActive,
        });
        toast('Sotuvchi yangilandi', 'success');
      } else {
        await createMarketplaceSeller({
          name: name.trim(),
          description: description.trim() || undefined,
          contactPhone: contactPhone.trim(),
          sellerType,
          ...location,
        });
        toast('Sotuvchi yaratildi', 'success');
      }
      setShowForm(false);
      resetForm();
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(false);
    }
  }

  async function saveCredential() {
    if (!editing) return;
    setCredErr('');
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
      await setSellerCredential(editing.id, credUsername.trim(), credPassword, editing.sellerType);
      setCredExists(true);
      setCredPassword('');
      toast("Kirish ma'lumoti saqlandi", 'success');
    } catch (e) {
      setCredErr((e as Error).message);
    } finally {
      setCredSaving(false);
    }
  }

  async function remove(s: MarketplaceSeller) {
    const ok = await dialog.confirm(`"${s.name}" sotuvchisini o'chirasizmi?`, {
      title: "Sotuvchini o'chirish",
      danger: true,
    });
    if (!ok) return;
    try {
      await deleteMarketplaceSeller(s.id);
      toast("O'chirildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  return (
    <div>
      <div className="row-sb" style={{ marginBottom: 16 }}>
        <div className="row" style={{ gap: 8 }}>
          {(['all', 'SHOP', 'CONSTRUCTION'] as const).map((t) => (
            <button
              key={t}
              className={`chip ${typeFilter === t ? 'active' : ''}`}
              onClick={() => setTypeFilter(t)}
            >
              {t === 'all' ? 'Barchasi' : TYPE_LABEL[t]}
            </button>
          ))}
        </div>
        <button className="btn" onClick={openCreate}>+ Yangi sotuvchi</button>
      </div>

      {showForm && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">{editing ? 'Sotuvchini tahrirlash' : 'Yangi sotuvchi'}</span>
          </div>
          <div className="card-body">
            <div className="form-grid form-grid-2" style={{ marginBottom: 14 }}>
              <div>
                <label>Nomi *</label>
                <input value={name} onChange={(e) => setName(e.target.value)} placeholder="masalan: Milano Kiyimlar" />
              </div>
              <div>
                <label>Aloqa telefoni *</label>
                <input value={contactPhone} onChange={(e) => setContactPhone(e.target.value)} placeholder="+998901234567" />
              </div>
            </div>
            <div style={{ marginBottom: 14 }}>
              <label>Tavsif</label>
              <input value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Qisqa tavsif" />
            </div>

            <div style={{ marginBottom: 14 }}>
              <label>Do'kon manzili</label>
              <input
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder="masalan: Beshariq, Mustaqillik ko'chasi 10"
              />
            </div>

            <div style={{ marginBottom: 14 }}>
              <div className="row-sb" style={{ marginBottom: 8 }}>
                <label style={{ margin: 0 }}>Joylashuv (xaritada)</label>
                <div className="row" style={{ gap: 8 }}>
                  {pin && (
                    <span className="text-sm" style={{ color: 'var(--green)', fontWeight: 600 }}>
                      📍 {pin.lat.toFixed(5)}, {pin.lng.toFixed(5)}
                    </span>
                  )}
                  <button type="button" className="btn ghost btn-sm" onClick={() => setShowMap((v) => !v)}>
                    {showMap ? 'Xaritani yopish' : pin ? "✏️ Joyni o'zgartirish" : '🗺 Xaritadan tanlash'}
                  </button>
                  {pin && (
                    <button type="button" className="btn ghost btn-sm" onClick={() => setPin(null)}>
                      Olib tashlash
                    </button>
                  )}
                </div>
              </div>
              {showMap && (
                <div style={{ borderRadius: 12, overflow: 'hidden', border: '1px solid var(--border)' }}>
                  <LocationMap
                    lat={pin?.lat ?? DEFAULT_LAT}
                    lng={pin?.lng ?? DEFAULT_LNG}
                    onPick={(lat, lng) => setPin({ lat, lng })}
                  />
                </div>
              )}
              <div className="text-sm muted" style={{ marginTop: 6 }}>
                Joylashuv kiritilsa — mijozlarga eng yaqin do'kon mahsulotlari birinchi ko'rsatiladi.
              </div>
            </div>

            {!editing && (
              <div className="form-grid form-grid-3" style={{ marginBottom: 14 }}>
                <div>
                  <label>Sotuvchi turi *</label>
                  <select value={sellerType} onChange={(e) => setSellerType(e.target.value as SellerType)}>
                    <option value="SHOP">Do'kon</option>
                    <option value="CONSTRUCTION">Qurilish</option>
                  </select>
                </div>
              </div>
            )}

            {editing && (
              <div className="row" style={{ marginBottom: 14, alignItems: 'center', gap: 8 }}>
                <input
                  type="checkbox"
                  id="seller-active"
                  checked={isActive}
                  onChange={(e) => setIsActive(e.target.checked)}
                />
                <label htmlFor="seller-active" style={{ margin: 0 }}>Faol (mijozlarga ko'rinadi)</label>
              </div>
            )}

            {formErr && <div className="err-block" style={{ marginBottom: 12 }}>{formErr}</div>}
            <div className="row">
              <button className="btn" disabled={busy} onClick={save}>
                {busy ? 'Saqlanmoqda...' : editing ? 'Saqlash' : 'Yaratish'}
              </button>
              <button className="btn ghost" onClick={() => { setShowForm(false); resetForm(); }}>Bekor qilish</button>
            </div>

            {editing && (
              <>
                <div className="divider" style={{ margin: '18px 0' }} />
                <div className="row-sb" style={{ marginBottom: 10 }}>
                  <span className="card-title" style={{ fontSize: 15 }}>Panel kirish ma'lumoti</span>
                  <span
                    className="text-sm"
                    style={{
                      color: credExists ? 'var(--green)' : 'var(--text-muted)',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                    }}
                  >
                    <span
                      style={{
                        width: 8,
                        height: 8,
                        borderRadius: '50%',
                        background: credExists ? 'var(--green)' : 'var(--text-muted)',
                        display: 'inline-block',
                      }}
                    />
                    {credExists ? 'Yaratilgan' : 'Yaratilmagan'}
                  </span>
                </div>
                <div className="form-grid form-grid-2" style={{ marginBottom: 12 }}>
                  <div>
                    <label>Login</label>
                    <input
                      value={credUsername}
                      autoComplete="off"
                      placeholder="masalan: milano_shop"
                      onChange={(e) => setCredUsername(e.target.value)}
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
                {credErr && <div className="err-block" style={{ marginBottom: 12 }}>{credErr}</div>}
                <button className="btn" disabled={credSaving} onClick={saveCredential}>
                  {credSaving
                    ? 'Saqlanmoqda…'
                    : credExists
                    ? '🔄 Parolni yangilash'
                    : '🔐 Kirish yaratish'}
                </button>

                <div className="divider" style={{ margin: '18px 0' }} />
                <div className="row-sb" style={{ marginBottom: 10 }}>
                  <span className="card-title" style={{ fontSize: 15 }}>Egalik (mobil ilova)</span>
                  <span
                    className="text-sm"
                    style={{
                      color: editing.ownerUserId ? 'var(--green)' : 'var(--text-muted)',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                    }}
                  >
                    <span
                      style={{
                        width: 8,
                        height: 8,
                        borderRadius: '50%',
                        background: editing.ownerUserId ? 'var(--green)' : 'var(--text-muted)',
                        display: 'inline-block',
                      }}
                    />
                    {editing.ownerUserId ? 'Biriktirilgan' : 'Biriktirilmagan'}
                  </span>
                </div>
                <div className="text-sm muted" style={{ marginBottom: 10 }}>
                  Telefon raqami bo&apos;yicha biriktirilgan foydalanuvchi Beshariq Go
                  ilovasida &quot;Mening do&apos;konim&quot; orqali native panelga kiradi.
                </div>
                <button className="btn ghost" onClick={() => setShowOwnerModal(true)}>
                  {editing.ownerUserId ? "🔄 Egasini almashtirish" : '👤 Ega biriktirish'}
                </button>
              </>
            )}
          </div>
        </div>
      )}

      {loading ? (
        <div className="card"><div className="sk sk-para" /></div>
      ) : sellers.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">🏪</div>
            <div className="empty-title">Sotuvchi yo'q</div>
          </div>
        </div>
      ) : (
        <div className="card" style={{ padding: 0 }}>
          {sellers.map((s, i) => (
            <div
              key={s.id}
              className="list-item"
              style={{ borderBottom: i < sellers.length - 1 ? '1px solid var(--border)' : 'none' }}
            >
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, color: 'var(--text)' }}>{s.name}</div>
                <div className="text-sm muted">
                  {s.contactPhone}
                  {s.address ? ` · 📍 ${s.address}` : ''}
                </div>
              </div>
              <span
                className="badge"
                style={{ background: s.sellerType === 'SHOP' ? 'var(--blue)' : 'var(--amber)' }}
              >
                {TYPE_LABEL[s.sellerType]}
              </span>
              <span
                className="badge"
                style={{ background: s.isActive ? 'var(--green)' : 'var(--red)' }}
              >
                {s.isActive ? 'Faol' : "Nofaol"}
              </span>
              <div className="row">
                <button className="btn ghost btn-sm" onClick={() => openEdit(s)}>✏️</button>
                <button className="btn red btn-sm" onClick={() => remove(s)}>🗑</button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showOwnerModal && editing && (
        <SellerOwnerAssignModal
          sellerId={editing.id}
          sellerName={editing.name}
          onClose={() => setShowOwnerModal(false)}
          onAssigned={async () => {
            const fresh = await getMarketplaceSellers(typeFilter === 'all' ? undefined : typeFilter);
            setSellers(fresh);
            setEditing((cur) => fresh.find((s) => s.id === cur?.id) ?? cur);
            toast('Ega biriktirildi', 'success');
          }}
        />
      )}
    </div>
  );
}

/* ============ Kategoriyalar ============ */
function CategoriesTab() {
  const toast = useToast();
  const dialog = useDialog();
  const [categories, setCategories] = useState<MarketplaceCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [typeFilter, setTypeFilter] = useState<SellerType>('SHOP');
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<MarketplaceCategory | null>(null);
  const [name, setName] = useState<I18nString>({ uz: '' });
  const [sortOrder, setSortOrder] = useState('0');
  const [busy, setBusy] = useState(false);
  const [formErr, setFormErr] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setCategories(
        (await getMarketplaceCategories(typeFilter)).sort((a, b) => a.sortOrder - b.sortOrder),
      );
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [typeFilter, toast]);

  useEffect(() => { load(); }, [load]);

  function openCreate() {
    setEditing(null);
    setName({ uz: '' });
    setSortOrder(String(categories.length));
    setFormErr('');
    setShowForm(true);
  }

  function openEdit(c: MarketplaceCategory) {
    setEditing(c);
    setName(c.name);
    setSortOrder(String(c.sortOrder));
    setFormErr('');
    setShowForm(true);
  }

  async function save() {
    setFormErr('');
    if (!name.uz.trim()) { setFormErr('Kategoriya nomini kiriting (uz)'); return; }
    setBusy(true);
    try {
      if (editing) {
        await updateMarketplaceCategory(editing.id, { name, sortOrder: parseInt(sortOrder, 10) || 0 });
        toast('Kategoriya yangilandi', 'success');
      } else {
        await createMarketplaceCategory({ name, sellerType: typeFilter, sortOrder: parseInt(sortOrder, 10) || 0 });
        toast('Kategoriya yaratildi', 'success');
      }
      setShowForm(false);
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(false);
    }
  }

  async function remove(c: MarketplaceCategory) {
    const ok = await dialog.confirm(
      `"${localeLabel(c.name)}" kategoriyasini o'chirasizmi?`,
      { title: "Kategoriyani o'chirish", danger: true },
    );
    if (!ok) return;
    try {
      await deleteMarketplaceCategory(c.id);
      toast("O'chirildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  return (
    <div>
      <div className="row-sb" style={{ marginBottom: 16 }}>
        <div className="row" style={{ gap: 8 }}>
          {(['SHOP', 'CONSTRUCTION'] as const).map((t) => (
            <button
              key={t}
              className={`chip ${typeFilter === t ? 'active' : ''}`}
              onClick={() => setTypeFilter(t)}
            >
              {TYPE_LABEL[t]}
            </button>
          ))}
        </div>
        <button className="btn" onClick={openCreate}>+ Yangi kategoriya</button>
      </div>

      {showForm && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">{editing ? 'Kategoriyani tahrirlash' : `Yangi kategoriya (${TYPE_LABEL[typeFilter]})`}</span>
          </div>
          <div className="card-body">
            <div style={{ marginBottom: 14 }}>
              <div className="form-grid form-grid-3">
                <div>
                  <label>Nomi (uz) *</label>
                  <input value={name.uz} onChange={(e) => setName({ ...name, uz: e.target.value })} />
                </div>
                <div>
                  <label>Nomi (кирилл)</label>
                  <input value={name.uz_Cyrl ?? ''} onChange={(e) => setName({ ...name, uz_Cyrl: e.target.value })} />
                </div>
                <div>
                  <label>Nomi (ru)</label>
                  <input value={name.ru ?? ''} onChange={(e) => setName({ ...name, ru: e.target.value })} />
                </div>
              </div>
            </div>
            <div className="form-grid form-grid-3" style={{ marginBottom: 14 }}>
              <div>
                <label>Tartib raqami</label>
                <input value={sortOrder} inputMode="numeric" onChange={(e) => setSortOrder(e.target.value.replace(/\D/g, ''))} />
              </div>
            </div>
            {formErr && <div className="err-block" style={{ marginBottom: 12 }}>{formErr}</div>}
            <div className="row">
              <button className="btn" disabled={busy} onClick={save}>
                {busy ? 'Saqlanmoqda...' : editing ? 'Saqlash' : 'Yaratish'}
              </button>
              <button className="btn ghost" onClick={() => setShowForm(false)}>Bekor qilish</button>
            </div>
          </div>
        </div>
      )}

      {loading ? (
        <div className="card"><div className="sk sk-para" /></div>
      ) : categories.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">📂</div>
            <div className="empty-title">Kategoriya yo'q</div>
          </div>
        </div>
      ) : (
        <div className="card" style={{ padding: 0 }}>
          {categories.map((c, i) => (
            <div key={c.id} className="list-item" style={{ borderBottom: i < categories.length - 1 ? '1px solid var(--border)' : 'none' }}>
              <span style={{ fontWeight: 600, color: 'var(--text)', flex: 1 }}>{localeLabel(c.name)}</span>
              <span className="text-sm muted">#{c.sortOrder}</span>
              <div className="row">
                <button className="btn ghost btn-sm" onClick={() => openEdit(c)}>✏️</button>
                <button className="btn red btn-sm" onClick={() => remove(c)}>🗑</button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
