'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  createCategory,
  createMenuItem,
  deleteMenuItem,
  formatSom,
  getCategories,
  getMenuItems,
  setAvailability,
} from '@/lib/api';
import type { Category, MenuItem } from '@/lib/types';

export default function MenuPage({ params }: { params: { id: string } }) {
  const rid = params.id;
  const [categories, setCategories] = useState<Category[]>([]);
  const [items, setItems] = useState<MenuItem[]>([]);
  const [error, setError] = useState<string | null>(null);

  // formalar
  const [catName, setCatName] = useState('');
  const [itemName, setItemName] = useState('');
  const [itemPrice, setItemPrice] = useState('');
  const [itemCat, setItemCat] = useState('');

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

  async function addCategory() {
    if (!catName.trim()) return;
    try {
      await createCategory(rid, { name: { uz: catName.trim() } });
      setCatName('');
      await load();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  async function addItem() {
    const price = parseInt(itemPrice, 10);
    if (!itemName.trim() || !itemCat || Number.isNaN(price)) return;
    try {
      await createMenuItem(rid, {
        categoryId: itemCat,
        name: { uz: itemName.trim() },
        price,
      });
      setItemName('');
      setItemPrice('');
      await load();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  async function toggle(item: MenuItem) {
    await setAvailability(rid, item.id, !item.isAvailable);
    await load();
  }

  async function remove(item: MenuItem) {
    await deleteMenuItem(rid, item.id);
    await load();
  }

  return (
    <div className="container">
      <h2 className="big" style={{ marginBottom: 16 }}>
        Menyu boshqaruvi
      </h2>
      {error && <p className="error">{error}</p>}

      {/* Yangi kategoriya */}
      <div className="card">
        <label>Yangi kategoriya</label>
        <div className="row">
          <input
            placeholder="Masalan: Salatlar"
            value={catName}
            onChange={(e) => setCatName(e.target.value)}
          />
          <button className="btn" onClick={addCategory}>
            Qo'shish
          </button>
        </div>
      </div>

      {/* Yangi taom */}
      <div className="card">
        <label>Yangi taom</label>
        <div style={{ display: 'grid', gap: 8 }}>
          <select value={itemCat} onChange={(e) => setItemCat(e.target.value)}>
            {categories.length === 0 && <option value="">Avval kategoriya qo'shing</option>}
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name.uz}
              </option>
            ))}
          </select>
          <input
            placeholder="Taom nomi"
            value={itemName}
            onChange={(e) => setItemName(e.target.value)}
          />
          <input
            placeholder="Narx (so'm)"
            inputMode="numeric"
            value={itemPrice}
            onChange={(e) => setItemPrice(e.target.value.replace(/[^0-9]/g, ''))}
          />
          <button className="btn" onClick={addItem} disabled={categories.length === 0}>
            Taom qo'shish
          </button>
        </div>
      </div>

      {/* Mavjud menyu */}
      {categories.map((c) => (
        <div className="card" key={c.id}>
          <div className="title" style={{ marginBottom: 8 }}>
            {c.name.uz}
          </div>
          {items.filter((i) => i.categoryId === c.id).length === 0 && (
            <p className="muted">Taom yo'q</p>
          )}
          {items
            .filter((i) => i.categoryId === c.id)
            .map((item) => (
              <div className="row" key={item.id} style={{ padding: '6px 0' }}>
                <div>
                  <div>{item.name.uz}</div>
                  <div className="muted">{formatSom(item.price)}</div>
                </div>
                <div className="btn-group">
                  <button
                    className={`btn ${item.isAvailable ? 'green' : 'ghost'}`}
                    onClick={() => toggle(item)}
                  >
                    {item.isAvailable ? 'Bor' : "Yo'q"}
                  </button>
                  <button className="btn red" onClick={() => remove(item)}>
                    O'chirish
                  </button>
                </div>
              </div>
            ))}
        </div>
      ))}
    </div>
  );
}
