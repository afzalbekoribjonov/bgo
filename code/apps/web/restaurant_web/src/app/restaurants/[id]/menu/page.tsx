'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  createCategory,
  createMenuItem,
  deleteCategory,
  deleteMenuItem,
  formatSom,
  getCategories,
  getMenuItems,
  setAvailability,
  updateCategory,
  updateMenuItem,
} from '@/lib/api';
import type { Category, MenuItem } from '@/lib/types';
import ImageUploader from '@/components/image-uploader';

type DeleteTarget =
  | { type: 'cat'; id: string; name: string }
  | { type: 'item'; id: string; name: string };

type EditItem = {
  id: string;
  name: string;
  price: string;
  categoryId: string;
  image: string;
};

export default function MenuPage({ params }: { params: { id: string } }) {
  const rid = params.id;
  const [categories, setCategories] = useState<Category[]>([]);
  const [items, setItems] = useState<MenuItem[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Add forms
  const [catName, setCatName] = useState('');
  const [itemName, setItemName] = useState('');
  const [itemPrice, setItemPrice] = useState('');
  const [itemCat, setItemCat] = useState('');
  const [itemImage, setItemImage] = useState<string | null>(null);

  // Edit/delete state
  const [editCatId, setEditCatId] = useState<string | null>(null);
  const [editCatName, setEditCatName] = useState('');
  const [editItem, setEditItem] = useState<EditItem | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<DeleteTarget | null>(null);

  const load = useCallback(async () => {
    try {
      const [c, m] = await Promise.all([getCategories(rid), getMenuItems(rid)]);
      setCategories(c);
      setItems(m);
      if (!itemCat && c.length > 0) setItemCat(c[0].id);
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    }
  }, [rid, itemCat]);

  useEffect(() => {
    load();
  }, [load]);

  async function withSave(fn: () => Promise<void>) {
    setSaving(true);
    setError(null);
    try {
      await fn();
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function addCategory() {
    if (!catName.trim()) return;
    await withSave(async () => {
      await createCategory(rid, { name: { uz: catName.trim() } });
      setCatName('');
    });
  }

  async function addItem() {
    const price = parseInt(itemPrice, 10);
    if (!itemName.trim() || !itemCat || Number.isNaN(price) || price <= 0)
      return;
    await withSave(async () => {
      await createMenuItem(rid, {
        categoryId: itemCat,
        name: { uz: itemName.trim() },
        price,
        ...(itemImage ? { imageUrl: itemImage } : {}),
      });
      setItemName('');
      setItemPrice('');
      setItemImage(null);
    });
  }

  async function saveCat() {
    if (!editCatId || !editCatName.trim()) return;
    const id = editCatId;
    await withSave(async () => {
      await updateCategory(rid, id, { name: { uz: editCatName.trim() } });
      setEditCatId(null);
      setEditCatName('');
    });
  }

  async function saveItem() {
    if (!editItem) return;
    const price = parseInt(editItem.price, 10);
    if (!editItem.name.trim() || Number.isNaN(price) || price <= 0) return;
    const snap = editItem;
    await withSave(async () => {
      await updateMenuItem(rid, snap.id, {
        name: { uz: snap.name.trim() },
        price,
        categoryId: snap.categoryId,
        imageUrl: snap.image,
      });
      setEditItem(null);
    });
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    const target = deleteTarget;
    await withSave(async () => {
      if (target.type === 'cat') {
        await deleteCategory(rid, target.id);
      } else {
        await deleteMenuItem(rid, target.id);
      }
      setDeleteTarget(null);
    });
  }

  async function toggle(item: MenuItem) {
    try {
      await setAvailability(rid, item.id, !item.isAvailable);
      await load();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  return (
    <div className="container" style={{ paddingBottom: 32 }}>
      <h2 className="big" style={{ marginBottom: 16 }}>
        Menyu boshqaruvi
      </h2>

      {error && (
        <div
          style={{
            background: 'rgba(224,49,49,0.07)',
            border: '1px solid rgba(224,49,49,0.3)',
            borderRadius: 12,
            padding: '12px 14px',
            marginBottom: 12,
            color: 'var(--red)',
            fontWeight: 700,
            fontSize: 14,
          }}
        >
          ⚠ {error}
        </div>
      )}

      {/* Yangi kategoriya */}
      <div className="card">
        <div className="sec-title">Yangi kategoriya</div>
        <div className="add-form-row">
          <input
            placeholder="Masalan: Salatlar, Sho'rvalar…"
            value={catName}
            onChange={(e) => setCatName(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && addCategory()}
          />
          <button
            className="btn"
            disabled={saving || !catName.trim()}
            onClick={addCategory}
          >
            + Qo&apos;shish
          </button>
        </div>
      </div>

      {/* Yangi taom */}
      <div className="card">
        <div className="sec-title">Yangi taom</div>
        <div style={{ display: 'grid', gap: 10 }}>
          <ImageUploader value={itemImage} onChange={setItemImage} />
          <div>
            <label>Kategoriya</label>
            <select
              value={itemCat}
              onChange={(e) => setItemCat(e.target.value)}
            >
              {categories.length === 0 && (
                <option value="">Avval kategoriya qo&apos;shing</option>
              )}
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name.uz}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label>Taom nomi</label>
            <input
              placeholder="Masalan: Lag'mon, Osh…"
              value={itemName}
              onChange={(e) => setItemName(e.target.value)}
            />
          </div>
          <div>
            <label>Narxi (so&apos;m)</label>
            <input
              placeholder="Masalan: 25000"
              inputMode="numeric"
              value={itemPrice}
              onChange={(e) =>
                setItemPrice(e.target.value.replace(/[^0-9]/g, ''))
              }
            />
          </div>
          <button
            className="btn"
            onClick={addItem}
            disabled={
              categories.length === 0 ||
              saving ||
              !itemName.trim() ||
              !itemPrice
            }
          >
            + Taom qo&apos;shish
          </button>
        </div>
      </div>

      {/* Mavjud menyu */}
      {categories.length === 0 && (
        <p className="empty">
          Hali kategoriya yo&apos;q — yuqorida kategoriya qo&apos;shing
        </p>
      )}

      {categories.map((c) => {
        const catItems = items.filter((i) => i.categoryId === c.id);
        const isEditingCat = editCatId === c.id;

        return (
          <div
            className="card"
            key={c.id}
            style={{ padding: 0, overflow: 'hidden' }}
          >
            {/* Kategoriya sarlavhasi */}
            <div className="cat-group-header">
              {isEditingCat ? (
                <div className="inline-edit">
                  <input
                    value={editCatName}
                    onChange={(e) => setEditCatName(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') saveCat();
                      if (e.key === 'Escape') setEditCatId(null);
                    }}
                    autoFocus
                  />
                  <button
                    className="btn sm green"
                    disabled={saving}
                    onClick={saveCat}
                  >
                    ✓
                  </button>
                  <button
                    className="btn sm ghost"
                    onClick={() => setEditCatId(null)}
                  >
                    ✕
                  </button>
                </div>
              ) : (
                <>
                  <span className="cat-group-name">{c.name.uz}</span>
                  <span className="cat-group-count">{catItems.length}</span>
                  <div className="cat-group-actions">
                    <button
                      className="icon-btn"
                      title="Nomini tahrirlash"
                      onClick={() => {
                        setEditCatId(c.id);
                        setEditCatName(c.name.uz);
                      }}
                    >
                      ✏
                    </button>
                    <button
                      className="icon-btn danger"
                      title="Kategoriyani o'chirish"
                      onClick={() =>
                        setDeleteTarget({
                          type: 'cat',
                          id: c.id,
                          name: c.name.uz,
                        })
                      }
                    >
                      🗑
                    </button>
                  </div>
                </>
              )}
            </div>

            {/* Taomlar ro'yxati */}
            {catItems.length === 0 && (
              <p
                className="muted"
                style={{ padding: '12px 16px', fontSize: 14 }}
              >
                Hali taom yo&apos;q
              </p>
            )}
            {catItems.map((item) => (
              <div
                className={`item-card ${item.isAvailable ? '' : 'unavailable'}`}
                key={item.id}
              >
                <div className="item-thumb">
                  {item.imageUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={item.imageUrl} alt={item.name.uz} />
                  ) : (
                    '🍽'
                  )}
                </div>
                <div className="item-info">
                  <div className="item-name">{item.name.uz}</div>
                  <div className="item-price">{formatSom(item.price)}</div>
                </div>
                <button
                  className={`avail-btn ${item.isAvailable ? 'on' : 'off'}`}
                  onClick={() => toggle(item)}
                >
                  {item.isAvailable ? '✓ Bor' : "✕ Yo'q"}
                </button>
                <button
                  className="icon-btn"
                  title="Tahrirlash"
                  onClick={() =>
                    setEditItem({
                      id: item.id,
                      name: item.name.uz,
                      price: String(item.price),
                      categoryId: item.categoryId,
                      image: item.imageUrl ?? '',
                    })
                  }
                >
                  ✏
                </button>
                <button
                  className="icon-btn danger"
                  title="O'chirish"
                  onClick={() =>
                    setDeleteTarget({
                      type: 'item',
                      id: item.id,
                      name: item.name.uz,
                    })
                  }
                >
                  🗑
                </button>
              </div>
            ))}
          </div>
        );
      })}

      {/* Taom tahrirlash modali */}
      {editItem && (
        <div className="modal-overlay" onClick={() => setEditItem(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-title">Taomni tahrirlash</div>
            <div style={{ display: 'grid', gap: 12 }}>
              <ImageUploader
                value={editItem.image || null}
                onChange={(url) =>
                  setEditItem({ ...editItem, image: url ?? '' })
                }
              />
              <div>
                <label>Taom nomi</label>
                <input
                  value={editItem.name}
                  onChange={(e) =>
                    setEditItem({ ...editItem, name: e.target.value })
                  }
                />
              </div>
              <div>
                <label>Narxi (so&apos;m)</label>
                <input
                  inputMode="numeric"
                  value={editItem.price}
                  onChange={(e) =>
                    setEditItem({
                      ...editItem,
                      price: e.target.value.replace(/[^0-9]/g, ''),
                    })
                  }
                />
              </div>
              <div>
                <label>Kategoriya</label>
                <select
                  value={editItem.categoryId}
                  onChange={(e) =>
                    setEditItem({ ...editItem, categoryId: e.target.value })
                  }
                >
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name.uz}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn ghost" onClick={() => setEditItem(null)}>
                Bekor qilish
              </button>
              <button
                className="btn green"
                disabled={
                  saving || !editItem.name.trim() || !editItem.price
                }
                onClick={saveItem}
              >
                {saving ? '…' : 'Saqlash'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* O'chirish tasdiqlash modali */}
      {deleteTarget && (
        <div className="modal-overlay" onClick={() => setDeleteTarget(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-title">
              {deleteTarget.type === 'cat'
                ? "Kategoriyani o'chirish"
                : "Taomni o'chirish"}
            </div>
            <div className="modal-sub">
              <b>{deleteTarget.name}</b>
              {deleteTarget.type === 'cat'
                ? " — kategoriya va undagi barcha taomlar o'chib ketadi."
                : " — taom menyudan o'chiriladi."}
              <br />
              Bu amalni bekor qilib bo&apos;lmaydi.
            </div>
            <div className="modal-footer">
              <button
                className="btn ghost"
                onClick={() => setDeleteTarget(null)}
              >
                Bekor qilish
              </button>
              <button
                className="btn red"
                disabled={saving}
                onClick={confirmDelete}
              >
                {saving ? '…' : "Ha, o'chirish"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
