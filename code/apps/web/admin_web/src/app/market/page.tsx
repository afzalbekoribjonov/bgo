'use client';

import { Fragment, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  adjustMarketStock,
  createMarketCategory,
  createMarketPickupLocation,
  createMarketProduct,
  deleteMarketCategory,
  deleteMarketComment,
  deleteMarketProduct,
  formatDate,
  formatSom,
  getMarketCategories,
  getMarketComments,
  getMarketPickupLocations,
  getMarketProducts,
  getMarketSettings,
  getMarketSupportMessages,
  getMarketSupportThreads,
  getStoreOrders,
  sendMarketSupportReply,
  setStoreOrderStatus,
  updateMarketCategory,
  updateMarketPickupLocation,
  updateMarketProduct,
  updateMarketSettings,
  uploadMarketImage,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import { NumInput } from '@/components/num-input';
import SizeEditor from '@/components/size-editor';
import ImageUploader from '@/components/image-uploader';
import type {
  I18nString,
  MarketCategory,
  MarketComment,
  MarketPickupLocation,
  MarketProduct,
  MarketSettings,
  MarketSupportMessage,
  MarketSupportThread,
  StoreOrder,
  StoreOrderStatus,
} from '@/lib/types';

type Tab = 'products' | 'categories' | 'orders' | 'support' | 'pickup' | 'settings';

const TABS: { id: Tab; label: string }[] = [
  { id: 'products', label: 'Mahsulotlar' },
  { id: 'categories', label: 'Kategoriyalar' },
  { id: 'orders', label: 'Buyurtmalar' },
  { id: 'support', label: 'Support chat' },
  { id: 'pickup', label: 'Olib ketish joylari' },
  { id: 'settings', label: 'Sozlamalar' },
];

const STATUS_LABEL: Record<StoreOrder['status'], string> = {
  PENDING: 'Kutilmoqda',
  ACCEPTED: 'Qabul qilindi',
  ARRIVED: 'Yetib keldi',
  PICKED_UP: 'Olindi',
  IN_TRANSIT: "Yo'lda",
  DELIVERED: 'Yetkazildi',
  PREPARING: "Yig'ilmoqda",
  READY_FOR_PICKUP: "Olib ketishga tayyor",
  COMPLETED: 'Yakunlandi',
  CANCELLED: 'Bekor qilindi',
};

const STATUS_DOT: Record<StoreOrder['status'], string> = {
  PENDING: 'dot-amber',
  ACCEPTED: 'dot-blue',
  ARRIVED: 'dot-blue',
  PICKED_UP: 'dot-blue',
  IN_TRANSIT: 'dot-blue',
  DELIVERED: 'dot-green',
  PREPARING: 'dot-amber',
  READY_FOR_PICKUP: 'dot-amber',
  COMPLETED: 'dot-green',
  CANCELLED: 'dot-red',
};

export default function MarketPage() {
  const [tab, setTab] = useState<Tab>('products');
  // Buyurtma kartasidan "Suhbat" bosilganda Support bo'limiga shu mijoz
  // ipini ochib o'tish uchun (bosqichlar orasidagi bog'lanish).
  const [chatTarget, setChatTarget] = useState<string | null>(null);

  const openChat = useCallback((customerId: string) => {
    setChatTarget(customerId);
    setTab('support');
  }, []);

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Beshariq Market</h1>
          <p className="page-subtitle">Mahsulotlar, kategoriyalar, buyurtmalar va support chat</p>
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

      {tab === 'products' && <ProductsTab />}
      {tab === 'categories' && <CategoriesTab />}
      {tab === 'orders' && <OrdersTab onOpenChat={openChat} />}
      {tab === 'support' && (
        <SupportTab initialCustomerId={chatTarget} onConsumeInitial={() => setChatTarget(null)} />
      )}
      {tab === 'pickup' && <PickupTab />}
      {tab === 'settings' && <SettingsTab />}
    </div>
  );
}

/* ============ Ko'p tilli nom kiritish ============ */
function I18nFields({
  value,
  onChange,
  label,
}: {
  value: I18nString;
  onChange: (v: I18nString) => void;
  label: string;
}) {
  return (
    <div className="form-grid form-grid-3">
      <div>
        <label>{label} (uz) *</label>
        <input value={value.uz} onChange={(e) => onChange({ ...value, uz: e.target.value })} />
      </div>
      <div>
        <label>{label} (кирилл)</label>
        <input
          value={value.uz_Cyrl ?? ''}
          onChange={(e) => onChange({ ...value, uz_Cyrl: e.target.value })}
        />
      </div>
      <div>
        <label>{label} (ru)</label>
        <input value={value.ru ?? ''} onChange={(e) => onChange({ ...value, ru: e.target.value })} />
      </div>
    </div>
  );
}

function localeLabel(v: I18nString): string {
  return v.uz || v.ru || v.uz_Cyrl || '';
}

/** Bir sahifada backend'dan so'raladigan mahsulotlar soni — katalog
 * kattalashganda hammasi bir yo'la yuklanib og'irlashib ketmasin. */
const PRODUCTS_PAGE_SIZE = 40;

/* ============ Mahsulotlar ============ */
function ProductsTab() {
  const toast = useToast();
  const dialog = useDialog();
  const [products, setProducts] = useState<MarketProduct[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [categories, setCategories] = useState<MarketCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [query, setQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<MarketProduct | null>(null);
  const [busy, setBusy] = useState(false);

  const [name, setName] = useState<I18nString>({ uz: '' });
  const [description, setDescription] = useState<I18nString>({ uz: '' });
  const [categoryId, setCategoryId] = useState('');
  const [price, setPrice] = useState('');
  const [stockQty, setStockQty] = useState('');
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [sizes, setSizes] = useState<string[]>([]);
  const [formErr, setFormErr] = useState('');
  const [comments, setComments] = useState<MarketComment[]>([]);

  // Jadvalda narxni joyida tahrirlash
  const [priceEditId, setPriceEditId] = useState<string | null>(null);
  const [priceDraft, setPriceDraft] = useState('');

  useEffect(() => {
    getMarketCategories().catch((e) => toast((e as Error).message, 'error')).then((c) => c && setCategories(c));
  }, [toast]);

  // Qidiruv — har bosilgan tugmada emas, 300ms sokinlikdan keyin serverga.
  useEffect(() => {
    const t = setTimeout(() => setDebouncedQuery(query.trim()), 300);
    return () => clearTimeout(t);
  }, [query]);

  const loadProducts = useCallback(async (targetPage: number, append: boolean) => {
    if (append) setLoadingMore(true); else setLoading(true);
    try {
      const res = await getMarketProducts({
        q: debouncedQuery || undefined,
        page: targetPage,
        pageSize: PRODUCTS_PAGE_SIZE,
      });
      setProducts((prev) => (append ? [...prev, ...res.items] : res.items));
      setTotal(res.total);
      setPage(res.page);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }, [toast, debouncedQuery]);

  // Qidiruv o'zgarsa (yoki dastlabki yuklashda) — 1-sahifadan qaytadan.
  useEffect(() => { loadProducts(1, false); }, [loadProducts]);
  const load = useCallback(() => loadProducts(1, false), [loadProducts]);

  function resetForm() {
    setEditing(null);
    setName({ uz: '' });
    setDescription({ uz: '' });
    setCategoryId(categories[0]?.id ?? '');
    setPrice('');
    setStockQty('');
    setImageUrls([]);
    setSizes([]);
    setFormErr('');
    setComments([]);
  }

  function openCreate() {
    resetForm();
    setShowForm(true);
  }

  async function openEdit(p: MarketProduct) {
    setEditing(p);
    setName(p.name);
    setDescription(p.description ?? { uz: '' });
    setCategoryId(p.categoryId);
    setPrice(String(p.price));
    setStockQty(String(p.stockQty));
    setImageUrls(p.imageUrls);
    setSizes(p.sizes ?? []);
    setFormErr('');
    setShowForm(true);
    try {
      setComments(await getMarketComments(p.id));
    } catch {
      setComments([]);
    }
  }

  async function removeComment(id: string) {
    try {
      await deleteMarketComment(id);
      setComments((arr) => arr.filter((c) => c.id !== id));
      toast("Izoh o'chirildi", 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  /** Jadvaldagi narxni joyida saqlash (Enter yoki fokus tashqarisi). */
  async function savePriceInline(p: MarketProduct) {
    const next = parseInt(priceDraft, 10);
    setPriceEditId(null);
    if (!Number.isFinite(next) || next < 0 || next === p.price) return;
    try {
      await updateMarketProduct(p.id, { price: next });
      toast(`Narx yangilandi: ${formatSom(next)}`, 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  async function save() {
    setFormErr('');
    if (!name.uz.trim()) { setFormErr('Mahsulot nomini kiriting (uz)'); return; }
    if (!categoryId) { setFormErr('Kategoriya tanlang'); return; }
    if (!price || parseInt(price, 10) < 0) { setFormErr("Narxni kiriting"); return; }
    setBusy(true);
    try {
      if (editing) {
        await updateMarketProduct(editing.id, {
          categoryId,
          name,
          description: description.uz.trim() ? description : undefined,
          price: parseInt(price, 10),
          imageUrls,
          sizes,
        });
        toast('Mahsulot yangilandi', 'success');
      } else {
        await createMarketProduct({
          categoryId,
          name,
          description: description.uz.trim() ? description : undefined,
          price: parseInt(price, 10),
          stockQty: parseInt(stockQty, 10) || 0,
          imageUrls,
          sizes,
        });
        toast('Mahsulot yaratildi', 'success');
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

  async function stock(p: MarketProduct, delta: number) {
    try {
      await adjustMarketStock(p.id, delta);
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  async function remove(p: MarketProduct) {
    const ok = await dialog.confirm(
      `"${localeLabel(p.name)}" mahsulotini o'chirasizmi?`,
      { title: "Mahsulotni o'chirish", danger: true },
    );
    if (!ok) return;
    try {
      await deleteMarketProduct(p.id);
      toast("O'chirildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  const categoryName = useMemo(() => {
    const map = new Map(categories.map((c) => [c.id, localeLabel(c.name)]));
    return (id: string) => map.get(id) ?? '—';
  }, [categories]);

  return (
    <div>
      <div className="row-sb" style={{ marginBottom: 16 }}>
        <span className="text-sm muted">{total} ta mahsulot</span>
        <button className="btn" onClick={openCreate} disabled={categories.length === 0}>
          + Yangi mahsulot
        </button>
      </div>

      {categories.length === 0 && !loading && (
        <div className="info-block amber" style={{ marginBottom: 16 }}>
          Avval "Kategoriyalar" bo'limida kamida bitta kategoriya yarating.
        </div>
      )}

      {showForm && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">{editing ? 'Mahsulotni tahrirlash' : 'Yangi mahsulot'}</span>
          </div>
          <div className="card-body">
            <div style={{ marginBottom: 14 }}>
              <I18nFields value={name} onChange={setName} label="Nomi" />
            </div>
            <div style={{ marginBottom: 14 }}>
              <I18nFields value={description} onChange={setDescription} label="Tavsif" />
            </div>
            <div className="form-grid form-grid-3" style={{ marginBottom: 14 }}>
              <div>
                <label>Kategoriya *</label>
                <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
                  <option value="">Tanlang</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>{localeLabel(c.name)}</option>
                  ))}
                </select>
              </div>
              <div>
                <label>Narx (so'm) *</label>
                <input
                  value={price}
                  inputMode="numeric"
                  placeholder="15000"
                  onChange={(e) => setPrice(e.target.value.replace(/\D/g, ''))}
                />
              </div>
              {!editing && (
                <div>
                  <label>Boshlang'ich zaxira</label>
                  <input
                    value={stockQty}
                    inputMode="numeric"
                    placeholder="0"
                    onChange={(e) => setStockQty(e.target.value.replace(/\D/g, ''))}
                  />
                </div>
              )}
            </div>

            <div style={{ marginBottom: 16 }}>
              <label>O'lchamlar</label>
              <SizeEditor value={sizes} onChange={setSizes} />
            </div>

            <div style={{ marginBottom: 14 }}>
              <label>Rasmlar</label>
              <ImageUploader value={imageUrls} onChange={setImageUrls} upload={uploadMarketImage} emptyIcon="🛒" />
            </div>

            {formErr && <div className="err-block" style={{ marginBottom: 12 }}>{formErr}</div>}
            <div className="row">
              <button className="btn" disabled={busy} onClick={save}>
                {busy ? 'Saqlanmoqda...' : editing ? 'Saqlash' : 'Yaratish'}
              </button>
              <button className="btn ghost" onClick={() => { setShowForm(false); resetForm(); }}>
                Bekor qilish
              </button>
            </div>

            {editing && (
              <>
                <div className="divider" />
                <label>Izohlar ({comments.length})</label>
                {comments.length === 0 ? (
                  <div className="text-sm muted">Hali izoh yo'q</div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    {comments.map((c) => (
                      <div key={c.id} className="row-sb" style={{ background: 'var(--surface-2)', padding: '8px 12px', borderRadius: 8 }}>
                        <span className="text-sm">{c.text}</span>
                        <button className="btn ghost btn-sm" onClick={() => removeComment(c.id)}>🗑</button>
                      </div>
                    ))}
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      )}

      {products.length > 0 && (
        <div style={{ marginBottom: 12, maxWidth: 320 }}>
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Mahsulot qidirish…"
          />
        </div>
      )}

      {loading ? (
        <div className="card"><div className="sk sk-para" /></div>
      ) : products.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">🛒</div>
            <div className="empty-title">{total === 0 && !debouncedQuery ? "Mahsulot yo'q" : 'Mahsulot topilmadi'}</div>
            <div className="empty-desc">{total === 0 && !debouncedQuery ? "Yangi mahsulot qo'shing" : 'Qidiruvni o\'zgartirib ko\'ring'}</div>
          </div>
        </div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Rasm</th>
                <th>Nomi</th>
                <th>Kategoriya</th>
                <th>Narx</th>
                <th>Zaxira</th>
                <th>Layk</th>
                <th>Holat</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {products.map((p) => (
                <tr key={p.id}>
                  <td>
                    {p.imageUrls[0] ? (
                      <img src={p.imageUrls[0]} alt="" style={{ width: 40, height: 40, objectFit: 'cover', borderRadius: 6 }} />
                    ) : (
                      <div style={{ width: 40, height: 40, borderRadius: 6, background: 'var(--surface-2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>🛒</div>
                    )}
                  </td>
                  <td style={{ fontWeight: 600, color: 'var(--text)' }}>{localeLabel(p.name)}</td>
                  <td>{categoryName(p.categoryId)}</td>
                  <td>
                    {priceEditId === p.id ? (
                      <input
                        className="price-edit-input"
                        value={priceDraft}
                        autoFocus
                        inputMode="numeric"
                        onChange={(e) => setPriceDraft(e.target.value.replace(/\D/g, ''))}
                        onBlur={() => savePriceInline(p)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') savePriceInline(p);
                          if (e.key === 'Escape') setPriceEditId(null);
                        }}
                      />
                    ) : (
                      <span
                        className="price-edit"
                        title="Narxni o'zgartirish uchun bosing"
                        onClick={() => { setPriceEditId(p.id); setPriceDraft(String(p.price)); }}
                      >
                        {formatSom(p.price)}
                      </span>
                    )}
                  </td>
                  <td>
                    <div className="row">
                      <button className="btn ghost btn-sm" onClick={() => stock(p, -1)} disabled={p.stockQty === 0}>−</button>
                      <span style={{ minWidth: 24, textAlign: 'center', fontWeight: 600 }}>{p.stockQty}</span>
                      <button className="btn ghost btn-sm" onClick={() => stock(p, 1)}>+</button>
                    </div>
                  </td>
                  <td>❤️ {p.likesCount}</td>
                  <td>
                    <span className="badge" style={{ background: p.isActive ? 'var(--green)' : '#64748b' }}>
                      {p.isActive ? 'Faol' : 'Nofaol'}
                    </span>
                  </td>
                  <td>
                    <div className="row">
                      <button className="btn ghost btn-sm" onClick={() => openEdit(p)}>✏️</button>
                      <button className="btn red btn-sm" onClick={() => remove(p)}>🗑</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {products.length < total && (
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <button className="btn ghost" disabled={loadingMore} onClick={() => loadProducts(page + 1, true)}>
            {loadingMore ? 'Yuklanmoqda…' : `Yana ko'rsatish (${total - products.length} ta qoldi)`}
          </button>
        </div>
      )}
    </div>
  );
}

/* ============ Kategoriyalar ============ */
function CategoriesTab() {
  const toast = useToast();
  const dialog = useDialog();
  const [categories, setCategories] = useState<MarketCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<MarketCategory | null>(null);
  const [name, setName] = useState<I18nString>({ uz: '' });
  const [sortOrder, setSortOrder] = useState('0');
  const [busy, setBusy] = useState(false);
  const [formErr, setFormErr] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setCategories((await getMarketCategories()).sort((a, b) => a.sortOrder - b.sortOrder));
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => { load(); }, [load]);

  function openCreate() {
    setEditing(null);
    setName({ uz: '' });
    setSortOrder(String(categories.length));
    setFormErr('');
    setShowForm(true);
  }

  function openEdit(c: MarketCategory) {
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
        await updateMarketCategory(editing.id, { name, sortOrder: parseInt(sortOrder, 10) || 0 });
        toast('Kategoriya yangilandi', 'success');
      } else {
        await createMarketCategory({ name, sortOrder: parseInt(sortOrder, 10) || 0 });
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

  async function remove(c: MarketCategory) {
    const ok = await dialog.confirm(
      `"${localeLabel(c.name)}" kategoriyasini o'chirasizmi?`,
      { title: "Kategoriyani o'chirish", danger: true },
    );
    if (!ok) return;
    try {
      await deleteMarketCategory(c.id);
      toast("O'chirildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  return (
    <div>
      <div className="row-sb" style={{ marginBottom: 16 }}>
        <span className="text-sm muted">{categories.length} ta kategoriya</span>
        <button className="btn" onClick={openCreate}>+ Yangi kategoriya</button>
      </div>

      {showForm && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">{editing ? 'Kategoriyani tahrirlash' : 'Yangi kategoriya'}</span>
          </div>
          <div className="card-body">
            <div style={{ marginBottom: 14 }}>
              <I18nFields value={name} onChange={setName} label="Nomi" />
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

/* ============ Buyurtmalar ============ */

/** Filtr chiplari uchun holatlar (eng ko'p ishlatiladigan tartibda). */
const STATUS_FILTERS: { id: StoreOrderStatus | 'all'; label: string }[] = [
  { id: 'all', label: 'Barchasi' },
  { id: 'PENDING', label: 'Kutilmoqda' },
  { id: 'PREPARING', label: "Yig'ilmoqda" },
  { id: 'READY_FOR_PICKUP', label: 'Olib ketishga tayyor' },
  { id: 'ACCEPTED', label: 'Qabul qilindi' },
  { id: 'IN_TRANSIT', label: "Yo'lda" },
  { id: 'DELIVERED', label: 'Yetkazildi' },
  { id: 'COMPLETED', label: 'Yakunlandi' },
  { id: 'CANCELLED', label: 'Bekor qilindi' },
];

/** Holat o'zgartirish tugmasining ko'rinishi. */
const TRANSITION_STYLE: Partial<Record<StoreOrderStatus, string>> = {
  CANCELLED: 'red',
  DELIVERED: 'green',
  COMPLETED: 'green',
};

/** Bir sahifada backend'dan so'raladigan buyurtmalar soni. */
const ORDERS_PAGE_SIZE = 30;

function OrdersTab({ onOpenChat }: { onOpenChat: (customerId: string) => void }) {
  const toast = useToast();
  const dialog = useDialog();
  const [orders, setOrders] = useState<StoreOrder[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [revenueSum, setRevenueSum] = useState(0);
  const [activeCount, setActiveCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [method, setMethod] = useState<'all' | 'DELIVERY' | 'PICKUP'>('all');
  const [status, setStatus] = useState<StoreOrderStatus | 'all'>('all');
  const [overduePickup, setOverduePickup] = useState(false);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  // Qidiruvni sekinlashtiramiz — har harfda so'rov yubormaslik uchun.
  useEffect(() => {
    const t = setTimeout(() => setDebouncedSearch(search.trim()), 300);
    return () => clearTimeout(t);
  }, [search]);

  const loadOrders = useCallback(async (targetPage: number, append: boolean) => {
    if (append) setLoadingMore(true); else setLoading(true);
    try {
      const res = await getStoreOrders({
        ...(status !== 'all' ? { status } : {}),
        ...(method !== 'all' ? { deliveryMethod: method } : {}),
        ...(debouncedSearch ? { q: debouncedSearch } : {}),
        ...(overduePickup ? { overduePickup: true } : {}),
        page: targetPage,
        pageSize: ORDERS_PAGE_SIZE,
      });
      setOrders((prev) => (append ? [...prev, ...res.items] : res.items));
      setTotal(res.total);
      setPage(res.page);
      setRevenueSum(res.revenueSum);
      setActiveCount(res.activeCount);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }, [status, method, overduePickup, debouncedSearch, toast]);

  // Filtr/qidiruv o'zgarsa (yoki dastlabki yuklashda) — 1-sahifadan qaytadan.
  useEffect(() => { loadOrders(1, false); }, [loadOrders]);
  const load = useCallback(() => loadOrders(1, false), [loadOrders]);

  /** Holatni o'zgartirish — bekor qilish uchun tasdiq so'raladi. */
  async function changeStatus(o: StoreOrder, next: StoreOrderStatus) {
    if (next === 'CANCELLED') {
      const ok = await dialog.confirm(
        `Buyurtma #${o.publicNo}ni bekor qilasizmi? Mahsulot zaxirasi omborga qaytariladi.`,
        { title: 'Buyurtmani bekor qilish', danger: true },
      );
      if (!ok) return;
    }
    setBusyId(o.id);
    try {
      await setStoreOrderStatus(o.id, next);
      toast(`#${o.publicNo}: ${STATUS_LABEL[next]}`, 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div>
      {/* Qidiruv + yangilash */}
      <div className="row-sb" style={{ marginBottom: 12, gap: 10 }}>
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="🔍 Buyurtma raqami (#12), mahsulot nomi yoki manzil…"
          style={{ flex: 1, maxWidth: 460 }}
        />
        <button className="btn ghost btn-sm" onClick={load} disabled={loading}>
          {loading ? 'Yuklanmoqda…' : '🔄 Yangilash'}
        </button>
      </div>

      {/* Holat filtri */}
      <div className="filters">
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.id}
            className={`chip ${status === f.id ? 'active' : ''}`}
            onClick={() => setStatus(f.id)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Yetkazish turi filtri */}
      <div className="filters">
        {(['all', 'DELIVERY', 'PICKUP'] as const).map((f) => (
          <button
            key={f}
            className={`chip ${method === f ? 'active' : ''}`}
            onClick={() => setMethod(f)}
          >
            {f === 'all' ? 'Barcha turlar' : f === 'DELIVERY' ? '🚗 Yetkazish' : '🏬 Olib ketish'}
          </button>
        ))}
        <button
          className={`chip ${overduePickup ? 'active' : ''}`}
          onClick={() => setOverduePickup((v) => !v)}
          title="READY_FOR_PICKUP holatida 3 kundan ortiq turgan buyurtmalar"
        >
          ⏰ 3 kundan oshgan
        </button>
      </div>

      {/* Qisqa hisob — joriy filtrga mos BUTUN to'plam bo'yicha (faqat yuklangan sahifa emas) */}
      {!loading && total > 0 && (
        <div className="row text-sm muted" style={{ gap: 16, marginBottom: 12 }}>
          <span><b style={{ color: 'var(--text)' }}>{total}</b> ta buyurtma</span>
          <span>Faol: <b style={{ color: 'var(--amber)' }}>{activeCount}</b></span>
          <span>Tushum: <b style={{ color: 'var(--text)' }}>{formatSom(revenueSum)}</b></span>
        </div>
      )}

      {loading ? (
        <div className="card"><div className="sk sk-para" /></div>
      ) : orders.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">📦</div>
            <div className="empty-title">
              {debouncedSearch ? 'Hech narsa topilmadi' : "Buyurtma yo'q"}
            </div>
            {debouncedSearch && (
              <div className="empty-desc">Boshqa raqam yoki nom bilan qidirib ko'ring</div>
            )}
          </div>
        </div>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>#</th>
                <th>Turi</th>
                <th>Mahsulotlar</th>
                <th>Summa</th>
                <th>Holat</th>
                <th>Vaqt</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => {
                const open = expandedId === o.id;
                const transitions = o.allowedTransitions ?? [];
                return (
                  <Fragment key={o.id}>
                    <tr
                      onClick={() => setExpandedId(open ? null : o.id)}
                      style={{ cursor: 'pointer' }}
                    >
                      <td style={{ fontWeight: 700 }}>#{o.publicNo}</td>
                      <td>{o.deliveryMethod === 'DELIVERY' ? '🚗 Yetkazish' : '🏬 Olib ketish'}</td>
                      <td className="text-sm">
                        {o.items
                          .map((it) => `${it.nameSnapshot}${it.size ? ` (${it.size})` : ''} ×${it.qty}`)
                          .join(', ')}
                      </td>
                      <td style={{ fontWeight: 600 }}>{formatSom(o.total)}</td>
                      <td>
                        <span className="row" style={{ gap: 6 }}>
                          <span className={`status-dot ${STATUS_DOT[o.status]}`} />
                          {STATUS_LABEL[o.status]}
                        </span>
                      </td>
                      <td className="text-sm muted">{formatDate(o.createdAt)}</td>
                      <td className="text-sm muted">{open ? '▲' : '▼'}</td>
                    </tr>

                    {open && (
                      <tr>
                        <td colSpan={7} style={{ background: 'var(--surface-2)' }}>
                          <div className="order-detail">
                            {/* Mijoz bloki — kim buyurtma bergani + bog'lanish */}
                            <div
                              className="row-sb"
                              style={{
                                background: 'var(--surface)',
                                border: '1px solid var(--border)',
                                borderRadius: 12,
                                padding: '12px 14px',
                                marginBottom: 14,
                              }}
                            >
                              <div>
                                <div className="order-detail-title" style={{ marginBottom: 4 }}>
                                  👤 Mijoz
                                </div>
                                <div style={{ fontWeight: 700, fontSize: 14.5 }}>
                                  {o.customer?.fullName || 'Ism kiritilmagan'}
                                </div>
                                <div className="text-sm muted">
                                  {o.customer?.phone ?? "Telefon noma'lum"}
                                </div>
                              </div>
                              <div className="row" style={{ gap: 8 }}>
                                {o.customer?.phone && (
                                  <a
                                    href={`tel:${o.customer.phone}`}
                                    className="btn ghost btn-sm"
                                    onClick={(e) => e.stopPropagation()}
                                  >
                                    📞 Qo&apos;ng&apos;iroq
                                  </a>
                                )}
                                <button
                                  className="btn btn-sm"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    onOpenChat(o.customerId);
                                  }}
                                >
                                  💬 Suhbat
                                </button>
                              </div>
                            </div>

                            <div className="order-detail-grid">
                              {/* Mahsulotlar */}
                              <div>
                                <div className="order-detail-title">Mahsulotlar</div>
                                {o.items.map((it, i) => (
                                  <div key={i} className="row-sb text-sm" style={{ padding: '4px 0' }}>
                                    <span>
                                      {it.nameSnapshot}
                                      {it.size && <span className="size-chip" style={{ marginLeft: 6, padding: '2px 8px', minWidth: 0 }}>{it.size}</span>}
                                      {' '}×{it.qty}
                                    </span>
                                    <span>{formatSom(it.lineTotal)}</span>
                                  </div>
                                ))}
                                <div className="divider" />
                                <div className="row-sb text-sm">
                                  <span className="muted">Mahsulotlar</span>
                                  <span>{formatSom(o.itemsTotal)}</span>
                                </div>
                                <div className="row-sb text-sm">
                                  <span className="muted">Yetkazish</span>
                                  <span>{o.deliveryFee ? formatSom(o.deliveryFee) : '—'}</span>
                                </div>
                                <div className="row-sb" style={{ fontWeight: 700, marginTop: 4 }}>
                                  <span>Jami</span>
                                  <span>{formatSom(o.total)}</span>
                                </div>
                              </div>

                              {/* Manzil + tarix */}
                              <div>
                                <div className="order-detail-title">
                                  {o.deliveryMethod === 'DELIVERY' ? 'Yetkazish manzili' : 'Olib ketish'}
                                </div>
                                <div className="text-sm" style={{ marginBottom: 12 }}>
                                  {o.address?.text ?? 'Ombordan olib ketiladi'}
                                </div>

                                <div className="order-detail-title">Holat tarixi</div>
                                {(o.statusHistory ?? []).length === 0 ? (
                                  <div className="text-sm muted">—</div>
                                ) : (
                                  (o.statusHistory ?? []).map((h, i) => (
                                    <div key={i} className="row text-sm" style={{ gap: 8, padding: '3px 0' }}>
                                      <span className={`status-dot ${STATUS_DOT[h.status]}`} />
                                      <span>{STATUS_LABEL[h.status]}</span>
                                      <span className="muted text-xs">{formatDate(h.at)}</span>
                                      {h.by && <span className="muted text-xs">· {h.by}</span>}
                                    </div>
                                  ))
                                )}
                              </div>
                            </div>

                            {/* Holatni o'zgartirish */}
                            <div className="divider" />
                            {transitions.length === 0 ? (
                              <div className="text-sm muted">
                                Bu buyurtma yakunlangan — holatni o'zgartirib bo'lmaydi.
                              </div>
                            ) : (
                              <div>
                                <div className="order-detail-title">Holatni o'zgartirish</div>
                                <div className="row" style={{ flexWrap: 'wrap', gap: 8 }}>
                                  {transitions.map((t) => (
                                    <button
                                      key={t}
                                      className={`btn btn-sm ${TRANSITION_STYLE[t] ?? 'ghost'}`}
                                      disabled={busyId === o.id}
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        changeStatus(o, t);
                                      }}
                                    >
                                      {STATUS_LABEL[t]}
                                    </button>
                                  ))}
                                </div>
                              </div>
                            )}
                          </div>
                        </td>
                      </tr>
                    )}
                  </Fragment>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {orders.length < total && (
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <button className="btn ghost" disabled={loadingMore} onClick={() => loadOrders(page + 1, true)}>
            {loadingMore ? 'Yuklanmoqda…' : `Yana ko'rsatish (${total - orders.length} ta qoldi)`}
          </button>
        </div>
      )}
    </div>
  );
}

/* ============ Support chat (real-time — polling asosida) ============ */
const CHAT_LIST_POLL_MS = 5000;
const CHAT_MSG_POLL_MS = 3000;

function threadDisplayName(t: { customer: MarketSupportThread['customer']; customerId: string }): string {
  return t.customer?.fullName || t.customer?.phone || `${t.customerId.slice(0, 8)}...`;
}

function SupportTab({
  initialCustomerId,
  onConsumeInitial,
}: {
  initialCustomerId: string | null;
  onConsumeInitial: () => void;
}) {
  const toast = useToast();
  const [threads, setThreads] = useState<MarketSupportThread[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<string | null>(null);
  const [messages, setMessages] = useState<MarketSupportMessage[]>([]);
  const [reply, setReply] = useState('');
  const [sending, setSending] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const selectedRef = useRef<string | null>(null);
  selectedRef.current = selected;

  const loadThreads = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      setThreads(await getMarketSupportThreads());
    } catch (e) {
      if (!silent) toast((e as Error).message, 'error');
    } finally {
      if (!silent) setLoading(false);
    }
  }, [toast]);

  // Suhbatlar ro'yxati — real-time his qildirish uchun muntazam yangilanadi
  // (yangi mijoz yozsa, admin sahifani yangilamasdan ko'radi).
  useEffect(() => {
    loadThreads();
    const t = setInterval(() => loadThreads(true), CHAT_LIST_POLL_MS);
    return () => clearInterval(t);
  }, [loadThreads]);

  const openThread = useCallback(async (customerId: string, silent = false) => {
    if (!silent) setSelected(customerId);
    try {
      const msgs = await getMarketSupportMessages(customerId);
      if (selectedRef.current === customerId || !silent) setMessages(msgs);
    } catch (e) {
      if (!silent) toast((e as Error).message, 'error');
    }
  }, [toast]);

  // Ochiq suhbat — yangi xabarlarni jonli kuzatish uchun tez-tez so'raladi.
  useEffect(() => {
    if (!selected) return;
    const t = setInterval(() => openThread(selected, true), CHAT_MSG_POLL_MS);
    return () => clearInterval(t);
  }, [selected, openThread]);

  // Buyurtma kartasidan "Suhbat" bosilsa — shu mijoz ipini avtomatik ochish.
  useEffect(() => {
    if (!initialCustomerId) return;
    openThread(initialCustomerId);
    onConsumeInitial();
  }, [initialCustomerId, openThread, onConsumeInitial]);

  // Yangi xabar kelsa — pastga avtomatik aylantirish.
  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight });
  }, [messages]);

  async function send() {
    if (!selected || !reply.trim()) return;
    setSending(true);
    try {
      await sendMarketSupportReply(selected, reply.trim());
      setReply('');
      setMessages(await getMarketSupportMessages(selected));
      await loadThreads(true);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setSending(false);
    }
  }

  const activeThread = threads.find((t) => t.customerId === selected) ?? null;

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '300px 1fr', gap: 16, minHeight: 480 }}>
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: 16 }}><div className="sk sk-para" /></div>
        ) : threads.length === 0 ? (
          <div className="empty"><div className="empty-icon">💬</div><div className="empty-title">Suhbat yo'q</div></div>
        ) : (
          threads.map((t) => (
            <button
              key={t.customerId}
              onClick={() => openThread(t.customerId)}
              className="list-item"
              style={{ width: '100%', border: 'none', background: selected === t.customerId ? 'var(--surface-hover)' : 'transparent', cursor: 'pointer' }}
            >
              <div style={{ flex: 1, minWidth: 0, textAlign: 'left' }}>
                <div className="text-sm font-semi" style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {threadDisplayName(t)}
                </div>
                <div className="text-xs muted" style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {t.lastMessage}
                </div>
              </div>
              {t.unseenCount > 0 && <span className="badge" style={{ background: 'var(--red)' }}>{t.unseenCount}</span>}
            </button>
          ))
        )}
      </div>

      <div className="card" style={{ display: 'flex', flexDirection: 'column', padding: 0, overflow: 'hidden' }}>
        {!selected ? (
          <div className="empty" style={{ margin: 'auto' }}>
            <div className="empty-icon">👈</div>
            <div className="empty-title">Suhbatni tanlang</div>
          </div>
        ) : (
          <>
            <div
              className="row-sb"
              style={{ padding: '12px 16px', borderBottom: '1px solid var(--border)', flexShrink: 0 }}
            >
              <div>
                <div style={{ fontWeight: 700, fontSize: 14.5 }}>
                  {activeThread ? threadDisplayName(activeThread) : selected.slice(0, 8) + '...'}
                </div>
                {activeThread?.customer?.phone && (
                  <div className="text-xs muted">{activeThread.customer.phone}</div>
                )}
              </div>
              {activeThread?.customer?.phone && (
                <a href={`tel:${activeThread.customer.phone}`} className="btn ghost btn-sm">
                  📞 Qo&apos;ng&apos;iroq
                </a>
              )}
            </div>
            <div
              ref={scrollRef}
              style={{ flex: 1, padding: 16, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 8 }}
            >
              {messages.map((m) => (
                <div
                  key={m.id}
                  style={{
                    alignSelf: m.senderRole === 'SUPPORT' ? 'flex-end' : 'flex-start',
                    maxWidth: '70%',
                  }}
                >
                  <div
                    style={{
                      background: m.senderRole === 'SUPPORT' ? 'var(--primary)' : 'var(--surface-2)',
                      color: m.senderRole === 'SUPPORT' ? '#fff' : 'var(--text)',
                      padding: '8px 12px',
                      borderRadius: 12,
                      fontSize: 13.5,
                    }}
                  >
                    {m.text}
                  </div>
                  <div
                    className="text-xs muted"
                    style={{ marginTop: 2, textAlign: m.senderRole === 'SUPPORT' ? 'right' : 'left' }}
                  >
                    {formatDate(m.createdAt)}
                  </div>
                </div>
              ))}
            </div>
            <div className="row" style={{ padding: 14, borderTop: '1px solid var(--border)', flexShrink: 0 }}>
              <input
                value={reply}
                placeholder="Javob yozing..."
                onChange={(e) => setReply(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') send(); }}
              />
              <button className="btn" disabled={sending || !reply.trim()} onClick={send}>Yuborish</button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

/* ============ Olib ketish joylari ============ */
/* ============ Sozlamalar (minimal buyurtma + do'kon holati) ============ */
function SettingsTab() {
  const toast = useToast();
  const dialog = useDialog();
  const [settings, setSettings] = useState<MarketSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [minOrderAmount, setMinOrderAmount] = useState('');
  const [isAcceptingOrders, setIsAcceptingOrders] = useState(true);

  useEffect(() => {
    setLoading(true);
    getMarketSettings()
      .then((s) => {
        setSettings(s);
        setMinOrderAmount(String(s.minOrderAmount));
        setIsAcceptingOrders(s.isAcceptingOrders);
      })
      .catch((e) => toast((e as Error).message, 'error'))
      .finally(() => setLoading(false));
  }, [toast]);

  async function save() {
    // Ochiqdan yopiqqa o'tish — barcha mijozlar checkout qila olmay qoladi,
    // shuning uchun boshqa "yopuvchi" harakatlar (masalan pickup joyni
    // faolsizlantirish) kabi tasdiq so'raladi.
    if (settings?.isAcceptingOrders !== false && !isAcceptingOrders) {
      const ok = await dialog.confirm(
        "Do'kon vaqtincha yopiladi — mijozlar buyurtma bera olmaydi.",
        { title: "Market'ni yopish", danger: true, confirmLabel: 'Yopish' },
      );
      if (!ok) return;
    }
    setSaving(true);
    try {
      const updated = await updateMarketSettings({
        minOrderAmount: parseInt(minOrderAmount, 10) || 0,
        isAcceptingOrders,
      });
      setSettings(updated);
      toast('Sozlamalar saqlandi ✓', 'success');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="card">
        <div className="card-body">
          <div className="sk sk-line sk-line-sm" style={{ marginBottom: 8, maxWidth: 240 }} />
          <div className="sk" style={{ height: 40, borderRadius: 8, maxWidth: 240 }} />
        </div>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap', alignItems: 'flex-start' }}>
      <div className="card" style={{ flex: 1, minWidth: 280, maxWidth: 420 }}>
        <div className="card-header">
          <span className="card-title">🛒 Market sozlamalari</span>
        </div>
        <div className="card-body">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
            <NumInput
              label="Minimal buyurtma summasi"
              value={minOrderAmount}
              onChange={setMinOrderAmount}
              suffix="so'm"
              hint="Savat summasi shundan kam bo'lsa checkout bloklanadi. 0 — cheklov yo'q."
            />
            <div>
              <label>Do&apos;kon holati</label>
              <div className="row-sb" style={{ marginTop: 6 }}>
                <span
                  className="badge"
                  style={{ background: isAcceptingOrders ? 'var(--green)' : '#64748b' }}
                >
                  {isAcceptingOrders ? 'Buyurtma qabul qilmoqda' : 'Vaqtincha yopiq'}
                </span>
                <button
                  className={`btn btn-sm ${isAcceptingOrders ? 'red' : 'green'}`}
                  onClick={() => setIsAcceptingOrders((v) => !v)}
                >
                  {isAcceptingOrders ? 'Vaqtincha yopish' : 'Qayta ochish'}
                </button>
              </div>
              <p style={{ fontSize: 12.5, color: 'var(--text-muted)', margin: '8px 0 0', lineHeight: 1.5 }}>
                Yopiq holatda mijozlar mahsulotlarni ko&apos;ra oladi, lekin checkout bloklanadi.
              </p>
            </div>
          </div>
          <div className="row" style={{ marginTop: 20 }}>
            <button className="btn" disabled={saving} onClick={save}>
              {saving ? (
                <>
                  <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
                  Saqlanmoqda&hellip;
                </>
              ) : (
                'Saqlash'
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function PickupTab() {
  const toast = useToast();
  const dialog = useDialog();
  const [locations, setLocations] = useState<MarketPickupLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<MarketPickupLocation | null>(null);
  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [lat, setLat] = useState('');
  const [lng, setLng] = useState('');
  const [busy, setBusy] = useState(false);
  const [formErr, setFormErr] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setLocations(await getMarketPickupLocations());
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => { load(); }, [load]);

  function openCreate() {
    setEditing(null);
    setName(''); setAddress(''); setLat(''); setLng('');
    setFormErr('');
    setShowForm(true);
  }

  function openEdit(l: MarketPickupLocation) {
    setEditing(l);
    setName(l.name); setAddress(l.address); setLat(String(l.lat)); setLng(String(l.lng));
    setFormErr('');
    setShowForm(true);
  }

  async function save() {
    setFormErr('');
    if (!name.trim() || !address.trim()) { setFormErr('Nom va manzilni kiriting'); return; }
    const latNum = parseFloat(lat);
    const lngNum = parseFloat(lng);
    if (Number.isNaN(latNum) || Number.isNaN(lngNum)) { setFormErr("Lat/Lng to'g'ri kiriting"); return; }
    setBusy(true);
    try {
      if (editing) {
        await updateMarketPickupLocation(editing.id, { name, address, lat: latNum, lng: lngNum });
        toast('Yangilandi', 'success');
      } else {
        await createMarketPickupLocation({ name, address, lat: latNum, lng: lngNum });
        toast('Yaratildi', 'success');
      }
      setShowForm(false);
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setBusy(false);
    }
  }

  /**
   * Joy o'chirilmaydi — faolsizlantiriladi (eski buyurtmalar shu joyga
   * bog'langan). Nofaol joy mijoz checkout ro'yxatida ko'rinmaydi.
   */
  async function toggleActive(l: MarketPickupLocation) {
    if (l.isActive) {
      const ok = await dialog.confirm(
        `"${l.name}" mijozlarga ko'rsatilmaydi. Eski buyurtmalar saqlanadi.`,
        { title: 'Joyni faolsizlantirish', danger: true, confirmLabel: 'Faolsizlantirish' },
      );
      if (!ok) return;
    }
    try {
      await updateMarketPickupLocation(l.id, { isActive: !l.isActive });
      toast(l.isActive ? 'Faolsizlantirildi' : 'Faollashtirildi', 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  return (
    <div>
      <div className="row-sb" style={{ marginBottom: 16 }}>
        <span className="text-sm muted">{locations.length} ta joy</span>
        <button className="btn" onClick={openCreate}>+ Yangi joy</button>
      </div>

      {showForm && (
        <div className="card" style={{ marginBottom: 16 }}>
          <div className="card-header">
            <span className="card-title">{editing ? 'Joyni tahrirlash' : 'Yangi olib ketish joyi'}</span>
          </div>
          <div className="card-body">
            <div className="form-grid form-grid-2" style={{ marginBottom: 14 }}>
              <div>
                <label>Nomi *</label>
                <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Markaziy ombor" />
              </div>
              <div>
                <label>Manzil *</label>
                <input value={address} onChange={(e) => setAddress(e.target.value)} placeholder="Beshariq, Markaz ko'chasi 1" />
              </div>
              <div>
                <label>Lat *</label>
                <input value={lat} onChange={(e) => setLat(e.target.value)} placeholder="40.9983" />
              </div>
              <div>
                <label>Lng *</label>
                <input value={lng} onChange={(e) => setLng(e.target.value)} placeholder="68.7561" />
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
      ) : locations.length === 0 ? (
        <div className="card">
          <div className="empty">
            <div className="empty-icon">📍</div>
            <div className="empty-title">Joy qo'shilmagan</div>
          </div>
        </div>
      ) : (
        <div className="card" style={{ padding: 0 }}>
          {locations.map((l, i) => (
            <div key={l.id} className="list-item" style={{ borderBottom: i < locations.length - 1 ? '1px solid var(--border)' : 'none' }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, color: 'var(--text)' }}>{l.name}</div>
                <div className="text-sm muted">{l.address}</div>
              </div>
              <span className="badge" style={{ background: l.isActive ? 'var(--green)' : '#64748b' }}>
                {l.isActive ? 'Faol' : 'Nofaol'}
              </span>
              <div className="row">
                <button className="btn ghost btn-sm" onClick={() => openEdit(l)}>✏️</button>
                <button
                  className={`btn btn-sm ${l.isActive ? 'red' : 'green'}`}
                  onClick={() => toggleActive(l)}
                >
                  {l.isActive ? 'Faolsizlantirish' : 'Faollashtirish'}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
