'use client';

import { useEffect, useRef, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { formatSom, getProduct } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useAuthState } from '@/lib/auth-context';
import type { Product } from '@/lib/types';

export default function ProductDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const toast = useToast();
  const { ready, authed } = useAuthState();

  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeSlide, setActiveSlide] = useState(0);
  const [selectedSize, setSelectedSize] = useState<string | null>(null);
  const [sizeErr, setSizeErr] = useState(false);
  const galleryRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!ready) return;
    setLoading(true);
    getProduct(id)
      .then(setProduct)
      .catch((e) => toast((e as Error).message, 'error'))
      .finally(() => setLoading(false));
  }, [ready, id]);

  function onGalleryScroll() {
    const el = galleryRef.current;
    if (!el) return;
    const idx = Math.round(el.scrollLeft / el.clientWidth);
    setActiveSlide(idx);
  }

  /**
   * Chatga o'tadi va birinchi xabarni tayyorlab beradi (mahsulot nomi +
   * tanlangan o'lcham) — sotuvchi nima haqida so'ralayotganini darrov biladi.
   */
  function contactViaChat() {
    if (!product) return;
    if (!authed) {
      toast('Yozishish uchun ilovadan oching', 'info');
      return;
    }
    if (product.sizes.length > 0 && !selectedSize) {
      setSizeErr(true);
      toast("Avval o'lchamni tanlang", 'info');
      return;
    }
    const prefill = selectedSize
      ? `Assalomu alaykum! "${product.name}" (o'lcham: ${selectedSize}) mavjudmi?`
      : `Assalomu alaykum! "${product.name}" mavjudmi?`;
    router.push(
      `/messages/${product.sellerId}?prefill=${encodeURIComponent(prefill)}`,
    );
  }

  if (!ready || loading) {
    return (
      <>
        <div className="topbar">
          <button className="topbar-back" onClick={() => router.back()}>←</button>
          <span className="topbar-title">Yuklanmoqda...</span>
        </div>
        <div className="content">
          <div className="sk" style={{ aspectRatio: 1, borderRadius: 16, marginBottom: 16 }} />
          <div className="sk sk-line" style={{ height: 20, width: '70%', marginBottom: 10 }} />
          <div className="sk sk-line" style={{ height: 16, width: '40%' }} />
        </div>
      </>
    );
  }

  if (!product) {
    return (
      <div className="empty">
        <div className="empty-icon">😕</div>
        <div className="empty-title">Mahsulot topilmadi</div>
      </div>
    );
  }

  const telHref = `tel:${product.sellerContactPhone}`;

  return (
    <>
      <div className="topbar">
        <button className="topbar-back" onClick={() => router.back()}>←</button>
        <span className="topbar-title">{product.name}</span>
      </div>
      <div className="content" style={{ paddingBottom: 24 }}>
        <div className="gallery" ref={galleryRef} onScroll={onGalleryScroll}>
          {product.imageUrls.length === 0 ? (
            <div className="gallery-slide">🛍️</div>
          ) : (
            product.imageUrls.map((url, i) => (
              <div key={i} className="gallery-slide">
                <img src={url} alt={product.name} />
              </div>
            ))
          )}
        </div>
        {product.imageUrls.length > 1 && (
          <div className="gallery-dots">
            {product.imageUrls.map((_, i) => (
              <span key={i} className={i === activeSlide ? 'active' : ''} />
            ))}
          </div>
        )}

        <span className="detail-price">{formatSom(product.price)}</span>
        <div className="detail-name">{product.name}</div>
        {product.description && <div className="detail-desc">{product.description}</div>}

        {product.sizes.length > 0 && (
          <div className="size-section">
            <div className="size-section-head">
              <span className="size-section-title">O'lcham</span>
              {selectedSize ? (
                <span className="size-picked">{selectedSize}</span>
              ) : (
                <span className={`size-hint ${sizeErr ? 'err' : ''}`}>Tanlang</span>
              )}
            </div>
            <div className="size-chip-row">
              {product.sizes.map((s) => (
                <button
                  key={s}
                  type="button"
                  className={`size-chip ${selectedSize === s ? 'active' : ''}`}
                  onClick={() => {
                    setSelectedSize(s);
                    setSizeErr(false);
                  }}
                >
                  {s}
                </button>
              ))}
            </div>
          </div>
        )}

        <div className="divider" />

        <div className="seller-card">
          <div className="seller-avatar">{product.sellerName.charAt(0).toUpperCase()}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="seller-name">{product.sellerName}</div>
            <div className="seller-phone">{product.sellerContactPhone}</div>
            {product.sellerAddress && (
              <div className="seller-address">📍 {product.sellerAddress}</div>
            )}
          </div>
          {product.distanceKm !== null && (
            <span className="dist-badge">{product.distanceKm} km</span>
          )}
        </div>

        <div className="contact-row">
          <a className="btn btn-lg" href={telHref}>📞 Qo'ng'iroq</a>
          <button className="btn ghost btn-sm" onClick={contactViaChat}>
            💬 Yozishish
          </button>
        </div>
      </div>
    </>
  );
}
