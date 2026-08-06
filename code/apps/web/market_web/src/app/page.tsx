'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { getCategories } from '@/lib/api';
import { PAGE_SIZE, useProducts } from '@/lib/use-products';
import { useToast } from '@/components/toast';
import { useAuthState } from '@/lib/auth-context';
import ProductCard from '@/components/product-card';
import RetryBanner from '@/components/retry-banner';
import type { Category } from '@/lib/types';

export default function HomePage() {
  const toast = useToast();
  const { ready, authed } = useAuthState();
  const [categories, setCategories] = useState<Category[]>([]);
  const [activeCategory, setActiveCategory] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');

  useEffect(() => {
    if (!ready) return;
    getCategories()
      .then((c) => setCategories(c.sort((a, b) => a.sortOrder - b.sortOrder)))
      .catch((e) => toast((e as Error).message, 'error'));
  }, [ready, toast]);

  // Qidiruv — har harfda emas, 300ms sokinlikdan keyin serverga.
  useEffect(() => {
    const t = setTimeout(() => setDebouncedSearch(search.trim()), 300);
    return () => clearTimeout(t);
  }, [search]);

  const {
    items: products,
    error,
    isLoadingInitial,
    isLoadingMore,
    isReachingEnd,
    loadMore,
    retry,
  } = useProducts(activeCategory, debouncedSearch);

  // "Ommabop" — faqat filtrsiz/qidiruvsiz asosiy ko'rinishda, yuklangan
  // BIRINCHI sahifa ichidan eng ko'p yoqtirilganlar (keyingi sahifalar
  // yuklangani sayin qayta aralashib ketmasligi uchun faqat 0..PAGE_SIZE
  // oralig'i ishlatiladi — bu doim "1-sahifa" bo'lib qoladi).
  const featured = useMemo(() => {
    if (activeCategory || debouncedSearch) return [];
    return [...products.slice(0, PAGE_SIZE)]
      .sort((a, b) => b.likesCount - a.likesCount)
      .slice(0, 4);
  }, [products, activeCategory, debouncedSearch]);

  // Pastga ~200px qolganda keyingi sahifani avtomatik yuklaydi.
  const sentinelRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = sentinelRef.current;
    if (!el || isReachingEnd || isLoadingMore || error) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) loadMore();
      },
      { rootMargin: '200px' },
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [isReachingEnd, isLoadingMore, error, loadMore]);

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
            👀 Ko&apos;rish rejimi — buyurtma berish uchun ilovadan oching
          </div>
        )}

        <div className="hero">
          <div className="hero-title">Beshariq Market</div>
          <div className="hero-sub">Kerakli mahsulotlarni buyurtma qiling — yetkazib beramiz yoki o&apos;zingiz olib keting</div>
          <div className="hero-chips">
            <span>🚚 Yetkazib berish</span>
            <span>🏬 Olib ketish</span>
            <span>💵 Naqd to&apos;lov</span>
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

        {featured.length > 0 && (
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

        {error ? (
          <RetryBanner message="Mahsulotlarni yuklab bo'lmadi" onRetry={retry} />
        ) : isLoadingInitial ? (
          <div className="product-grid">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="sk sk-card" />
            ))}
          </div>
        ) : products.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">🛒</div>
            <div className="empty-title">Mahsulot topilmadi</div>
            <div className="empty-desc">Boshqa kategoriya yoki qidiruvni sinab ko&apos;ring</div>
          </div>
        ) : (
          <>
            <div className="product-grid">
              {products.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
            {!isReachingEnd && (
              <div ref={sentinelRef} className="product-grid" style={{ marginTop: 12 }}>
                {isLoadingMore &&
                  [...Array(2)].map((_, i) => <div key={`more-${i}`} className="sk sk-card" />)}
              </div>
            )}
          </>
        )}
      </div>
    </>
  );
}
