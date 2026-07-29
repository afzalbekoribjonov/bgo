'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  createProduct,
  deleteProduct,
  formatSom,
  getCategories,
  getMyProducts,
  updateProduct,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import SizeEditor from '@/components/size-editor';
import ImageUploader from '@/components/image-uploader';
import { useAuthState } from '@/lib/auth-context';
import type { Product } from '@/lib/types';

interface CategoryOption {
  id: string;
  name: string;
}

export default function ProductsPage() {
  const toast = useToast();
  const dialog = useDialog();
  const { sellerType } = useAuthState();
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<CategoryOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<Product | null>(null);
  const [busy, setBusy] = useState(false);

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [price, setPrice] = useState('');
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [sizes, setSizes] = useState<string[]>([]);
  const [isActive, setIsActive] = useState(true);
  const [formErr, setFormErr] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [p, c] = await Promise.all([
        getMyProducts(),
        sellerType ? getCategories(sellerType) : Promise.resolve([]),
      ]);
      setProducts(p);
      setCategories(c);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [sellerType, toast]);

  useEffect(() => { load(); }, [load]);

  function resetForm() {
    setEditing(null);
    setName('');
    setDescription('');
    setCategoryId('');
    setPrice('');
    setImageUrls([]);
    setSizes([]);
    setIsActive(true);
    setFormErr('');
  }

  function openCreate() {
    resetForm();
    setShowForm(true);
  }

  function openEdit(p: Product) {
    setEditing(p);
    setName(p.name.uz);
    setDescription(p.description?.uz ?? '');
    setCategoryId(p.categoryId ?? '');
    setPrice(String(p.price));
    setImageUrls(p.imageUrls);
    setSizes(p.sizes ?? []);
    setIsActive(p.isActive);
    setFormErr('');
    setShowForm(true);
  }

  async function save() {
    setFormErr('');
    if (!name.trim()) { setFormErr('Mahsulot nomini kiriting'); return; }
    if (!price || parseInt(price, 10) < 0) { setFormErr('Narxni kiriting'); return; }
    setBusy(true);
    try {
      const dto = {
        categoryId: categoryId || undefined,
        name: { uz: name.trim() },
        description: description.trim() ? { uz: description.trim() } : undefined,
        price: parseInt(price, 10),
        imageUrls,
        sizes,
        isActive,
      };
      if (editing) {
        await updateProduct(editing.id, dto);
        toast('Mahsulot yangilandi', 'success');
      } else {
        await createProduct(dto);
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

  async function remove(p: Product) {
    const ok = await dialog.confirm(`"${p.name.uz}" mahsulotini o'chirasizmi?`, {
      title: "Mahsulotni o'chirish",
      danger: true,
    });
    if (!ok) return;
    try {
      await deleteProduct(p.id);
      toast("O'chirildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  return (
    <>
      <div className="topbar">
        <span className="topbar-title">📦 Mahsulotlarim</span>
      </div>
      <div className="content">
        {showForm ? (
          <div className="card card-p" style={{ marginBottom: 16 }}>
            <div className="section-title">{editing ? 'Mahsulotni tahrirlash' : 'Yangi mahsulot'}</div>

            <div className="field">
              <label>Nomi *</label>
              <input value={name} onChange={(e) => setName(e.target.value)} placeholder="masalan: Erkaklar futbolkasi" />
            </div>
            <div className="field">
              <label>Tavsif</label>
              <input value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Qisqa tavsif" />
            </div>
            <div className="field">
              <label>Narxi (so'm) *</label>
              <input value={price} inputMode="numeric" onChange={(e) => setPrice(e.target.value.replace(/\D/g, ''))} placeholder="85000" />
            </div>
            {categories.length > 0 && (
              <div className="field">
                <label>Kategoriya</label>
                <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
                  <option value="">Tanlanmagan</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
            )}

            <div className="field">
              <label>O'lchamlar</label>
              <SizeEditor value={sizes} onChange={setSizes} />
            </div>

            <div className="field">
              <label>Rasmlar</label>
              <ImageUploader value={imageUrls} onChange={setImageUrls} />
            </div>

            {editing && (
              <div className="row" style={{ marginBottom: 14, gap: 8 }}>
                <input
                  type="checkbox"
                  id="prod-active"
                  checked={isActive}
                  onChange={(e) => setIsActive(e.target.checked)}
                />
                <label htmlFor="prod-active" style={{ margin: 0, textTransform: 'none', fontSize: 13.5 }}>
                  Faol (mijozlarga ko'rinadi)
                </label>
              </div>
            )}

            {formErr && <div className="err-block">{formErr}</div>}
            <div className="row">
              <button className="btn" disabled={busy} onClick={save}>
                {busy ? 'Saqlanmoqda…' : editing ? 'Saqlash' : 'Yaratish'}
              </button>
              <button className="btn ghost" onClick={() => { setShowForm(false); resetForm(); }}>Bekor qilish</button>
            </div>
          </div>
        ) : (
          <div className="row-sb" style={{ marginBottom: 16 }}>
            <span className="text-sm muted">{products.length} ta mahsulot</span>
            <button className="btn" onClick={openCreate}>+ Yangi mahsulot</button>
          </div>
        )}

        {loading ? (
          <div className="product-grid">
            {[...Array(4)].map((_, i) => <div key={i} className="sk sk-card" />)}
          </div>
        ) : products.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">📦</div>
            <div className="empty-title">Mahsulot yo'q</div>
            <div className="empty-desc">Birinchi mahsulotingizni qo'shing</div>
          </div>
        ) : (
          <div className="product-grid">
            {products.map((p) => (
              <div key={p.id} className="product-card" onClick={() => openEdit(p)}>
                <div className="product-card-img">
                  {p.imageUrls[0] ? <img src={p.imageUrls[0]} alt={p.name.uz} /> : '📦'}
                  {!p.isActive && <span className="stock-tag out">Nofaol</span>}
                </div>
                <div className="product-card-body">
                  <div className="product-card-name">{p.name.uz}</div>
                  <div className="product-card-price">{formatSom(p.price)}</div>
                  {p.sizes?.length > 0 && (
                    <div className="product-card-meta">📏 {p.sizes.join(' · ')}</div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {editing && showForm && (
          <div className="row" style={{ marginTop: 8 }}>
            <button className="btn red btn-block" onClick={() => remove(editing)}>🗑 Mahsulotni o'chirish</button>
          </div>
        )}
      </div>
    </>
  );
}
