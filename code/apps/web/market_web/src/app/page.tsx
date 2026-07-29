'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { getCategories, getProducts } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useAuthState } from '@/lib/auth-context';
import ProductCard from '@/components/product-card';
import type { Category, Product } from '@/lib/types';

export default function HomePage() {
  const toast = useToast();
  const { ready, authed } = useAuthState();
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [activeCategory, setActiveCategory] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [c, p] = await Promise.all([getCategories(), getProducts()]);
      setCategories(c.sort((a, b) => a.sortOrder - b.sortOrder));
      setProducts(p);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    if (ready) load();
  }, [ready, load]);

  const filtered = useMemo(() => {
    let list = products;
    if (activeCategory) list = list.filter((p) => p.categoryId === activeCategory);
    const q = search.trim().toLowerCase();
    if (q) list = list.filter((p) => p.name.toLowerCase().includes(q));
    return list;
  }, [products, activeCategory, search]);

  const featured = useMemo(
    () => [...products].sort((a, b) => b.likesCount - a.likesCount).slice(0, 4),
    [products],
  );

  if (!ready) {
    return (
      <div className="loading-page">
        <div className="spinner" />
      </div>
    );
  }

  return (
    <>
      <div className="topbar">
        <span className="topbar-title">
          <span className="brand-logo">🛒</span>
          Beshariq Market
        </span>
      </div>
      <div className="content">
        {!authed && (
          <div className="view-only-banner">
            👀 Ko'rish rejimi — buyurtma berish uchun ilovadan oching
          </div>
        )}

        <div className="hero">
          <div className="hero-title">Beshariq Market</div>
          <div className="hero-sub">Kerakli mahsulotlarni buyurtma qiling — yetkazib beramiz yoki o'zingiz olib keting</div>
          <div className="hero-chips">
            <span>🚚 Yetkazib berish</span>
            <span>🏬 Olib ketish</span>
            <span>💵 Naqd to'lov</span>
          </div>
          <span className="hero-emoji">🛍️</span>
        </div>

        <div className="search-box">
          <span className="search-ic">🔍</span>
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Mahsulot qidirish…"
          />
        </div>

        <div className="cat-row">
          <button
            className={`cat-chip ${activeCategory === null ? 'active' : ''}`}
            onClick={() => setActiveCategory(null)}
          >
            Barchasi
          </button>
          {categories.map((c) => (
            <button
              key={c.id}
              className={`cat-chip ${activeCategory === c.id ? 'active' : ''}`}
              onClick={() => setActiveCategory(c.id)}
            >
              {c.name}
            </button>
          ))}
        </div>

        {!activeCategory && !search && featured.length > 0 && (
          <>
            <div className="section-title">🔥 Ommabop</div>
            <div className="product-grid" style={{ marginBottom: 24 }}>
              {featured.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
          </>
        )}

        <div className="section-title">
          {activeCategory ? categories.find((c) => c.id === activeCategory)?.name : 'Barcha mahsulotlar'}
        </div>

        {loading ? (
          <div className="product-grid">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="sk sk-card" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">🛒</div>
            <div className="empty-title">Mahsulot topilmadi</div>
            <div className="empty-desc">Boshqa kategoriya yoki qidiruvni sinab ko'ring</div>
          </div>
        ) : (
          <div className="product-grid">
            {filtered.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        )}
      </div>
    </>
  );
}
