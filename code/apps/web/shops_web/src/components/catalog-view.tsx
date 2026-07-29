'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { getCategories, getProducts } from '@/lib/api';
import { useToast } from './toast';
import { useAuthState } from '@/lib/auth-context';
import ProductCard from './product-card';
import type { Category, Product, SellerType } from '@/lib/types';

export default function CatalogView({
  sellerType,
  title,
  subtitle,
  emoji,
}: {
  sellerType: SellerType;
  title: string;
  subtitle: string;
  emoji: string;
}) {
  const toast = useToast();
  const { ready, authed } = useAuthState();
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [activeCategory, setActiveCategory] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [geo, setGeo] = useState<{ lat: number; lng: number } | null>(null);

  // Mijoz joylashuvi — "eng yaqin do'kon birinchi". Ruxsat berilmasa jim o'tadi.
  useEffect(() => {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) =>
        setGeo({
          lat: parseFloat(pos.coords.latitude.toFixed(6)),
          lng: parseFloat(pos.coords.longitude.toFixed(6)),
        }),
      () => {},
      { timeout: 6000, maximumAge: 300000 },
    );
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [c, p] = await Promise.all([
        getCategories(sellerType),
        getProducts(sellerType, geo ? { near: geo } : undefined),
      ]);
      setCategories(c.sort((a, b) => a.sortOrder - b.sortOrder));
      setProducts(p);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [sellerType, geo]);

  useEffect(() => {
    if (ready) load();
  }, [ready, load]);

  useEffect(() => {
    setActiveCategory(null);
    setSearch('');
  }, [sellerType]);

  const filtered = useMemo(() => {
    let list = products;
    if (activeCategory) list = list.filter((p) => p.categoryId === activeCategory);
    const q = search.trim().toLowerCase();
    if (q) list = list.filter((p) => p.name.toLowerCase().includes(q));
    return list;
  }, [products, activeCategory, search]);

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
        <span className="topbar-title">{emoji} {title}</span>
      </div>
      <div className="content">
        {!authed && (
          <div className="view-only-banner">
            👀 Ko'rish rejimi — sotuvchi bilan bog'lanish uchun ilovadan oching
          </div>
        )}

        <div className="hero">
          <div className="hero-title">{title}</div>
          <div className="hero-sub">{subtitle}</div>
          <span className="hero-emoji">{emoji}</span>
        </div>

        <div className="field" style={{ marginBottom: 16 }}>
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="🔍 Mahsulot qidirish..."
          />
        </div>

        {categories.length > 0 && (
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
        )}

        <div className="row-sb" style={{ marginBottom: 12 }}>
          <div className="section-title" style={{ marginBottom: 0 }}>
            {activeCategory ? categories.find((c) => c.id === activeCategory)?.name : 'Barcha mahsulotlar'}
          </div>
          {geo && products.some((p) => p.distanceKm !== null) && (
            <span className="near-badge">📍 Eng yaqini birinchi</span>
          )}
        </div>

        {loading ? (
          <div className="product-grid">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="sk sk-card" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">{emoji}</div>
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
