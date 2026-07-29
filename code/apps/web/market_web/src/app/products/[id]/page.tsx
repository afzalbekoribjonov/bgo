'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  addComment,
  formatSom,
  getComments,
  getProduct,
  likeProduct,
  timeAgo,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import { useAuthState } from '@/lib/auth-context';
import { useCart } from '@/lib/cart';
import type { Product, ProductComment } from '@/lib/types';

export default function ProductDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const toast = useToast();
  const { ready, authed } = useAuthState();
  const cart = useCart();

  const [product, setProduct] = useState<Product | null>(null);
  const [comments, setComments] = useState<ProductComment[]>([]);
  const [loading, setLoading] = useState(true);
  const [qty, setQty] = useState(1);
  const [selectedSize, setSelectedSize] = useState<string | null>(null);
  const [sizeErr, setSizeErr] = useState(false);
  const [commentText, setCommentText] = useState('');
  const [sendingComment, setSendingComment] = useState(false);
  const [liking, setLiking] = useState(false);
  const [activeSlide, setActiveSlide] = useState(0);
  const galleryRef = useRef<HTMLDivElement>(null);

  /** Galereya surilganda pastdagi nuqtalarni yangilaydi. */
  function onGalleryScroll() {
    const el = galleryRef.current;
    if (!el) return;
    setActiveSlide(Math.round(el.scrollLeft / el.clientWidth));
  }

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [p, c] = await Promise.all([getProduct(id), getComments(id)]);
      setProduct(p);
      setComments(c);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [id, toast]);

  useEffect(() => {
    if (ready) load();
  }, [ready, load]);

  async function toggleLike() {
    if (!authed) {
      toast('Layk bosish uchun ilovadan oching', 'info');
      return;
    }
    if (!product || product.liked || liking) return;
    setLiking(true);
    try {
      const res = await likeProduct(product.id);
      setProduct({ ...product, likesCount: res.likesCount, liked: true });
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLiking(false);
    }
  }

  async function sendComment() {
    if (!authed) {
      toast('Izoh qoldirish uchun ilovadan oching', 'info');
      return;
    }
    if (!commentText.trim()) return;
    setSendingComment(true);
    try {
      const c = await addComment(id, commentText.trim());
      setComments((arr) => [c, ...arr]);
      setCommentText('');
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setSendingComment(false);
    }
  }

  function addToCart() {
    if (!product) return;
    if (!authed) {
      toast('Savatga qo\'shish uchun ilovadan oching', 'info');
      return;
    }
    // O'lchamli mahsulotda tanlov majburiy (server ham tekshiradi).
    if (product.sizes.length > 0 && !selectedSize) {
      setSizeErr(true);
      toast("Avval o'lchamni tanlang", 'info');
      return;
    }
    cart.add(
      {
        productId: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrls[0] ?? null,
        stockQty: product.stockQty,
        ...(selectedSize ? { size: selectedSize } : {}),
      },
      qty,
    );
    toast("Savatga qo'shildi", 'success');
    router.push('/cart');
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

  return (
    <>
      <div className="topbar">
        <button className="topbar-back" onClick={() => router.back()}>←</button>
        <span className="topbar-title">{product.name}</span>
      </div>
      <div className="content" style={{ paddingBottom: product.inStock ? 100 : 24 }}>
        <div className="gallery" ref={galleryRef} onScroll={onGalleryScroll}>
          {product.imageUrls.length === 0 ? (
            <div className="gallery-slide">🛒</div>
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

        <div className="row-sb">
          <span className="detail-price">{formatSom(product.price)}</span>
          {product.inStock ? (
            <span className="status-badge" style={{ background: 'var(--green-light)', color: '#166534' }}>
              <span className="status-dot" style={{ background: 'var(--green)' }} />
              {product.stockQty} dona mavjud
            </span>
          ) : (
            <span className="status-badge" style={{ background: 'var(--red-light)', color: '#991b1b' }}>
              <span className="status-dot" style={{ background: 'var(--red)' }} />
              Tugagan
            </span>
          )}
        </div>

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

        <div className="detail-stats">
          <button className={`detail-stat ${product.liked ? 'liked' : ''}`} onClick={toggleLike} disabled={liking || product.liked}>
            {product.liked ? '❤️' : '🤍'} {product.likesCount}
          </button>
          {product.ratingAvg !== null && (
            <span className="detail-stat">⭐ {product.ratingAvg.toFixed(1)}</span>
          )}
          <span className="detail-stat">💬 {comments.length}</span>
        </div>

        <div className="divider" />

        <div className="section-title">Izohlar ({comments.length})</div>
        <div className="comment-composer">
          <input
            value={commentText}
            onChange={(e) => setCommentText(e.target.value)}
            placeholder="Izoh yozing..."
            onKeyDown={(e) => { if (e.key === 'Enter') sendComment(); }}
          />
          <button className="comment-send-btn" disabled={sendingComment || !commentText.trim()} onClick={sendComment} aria-label="Yuborish">
            ➤
          </button>
        </div>
        {comments.length === 0 ? (
          <div className="empty" style={{ padding: '28px 20px' }}>
            <div className="empty-icon">💬</div>
            <div className="empty-title">Hali izoh yo'q</div>
            <div className="empty-desc">Birinchi bo'lib fikr bildiring</div>
          </div>
        ) : (
          <div className="comment-list">
            {comments.map((c) => (
              <div key={c.id} className="comment-item">
                <div className="comment-avatar">
                  {c.user?.fullName ? c.user.fullName.charAt(0).toUpperCase() : '👤'}
                </div>
                <div className="comment-body">
                  <div className="comment-head">
                    <span className="comment-name">{c.user?.fullName ?? 'Foydalanuvchi'}</span>
                    <span className="comment-time">{timeAgo(c.createdAt)}</span>
                  </div>
                  <div className="comment-text">{c.text}</div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {product.inStock && (
        <div className="fixed-cta">
          <div className="card card-p row-sb">
            <div className="qty-stepper">
              <button onClick={() => setQty((q) => Math.max(1, q - 1))} disabled={qty <= 1}>−</button>
              <span className="qty-val">{qty}</span>
              <button onClick={() => setQty((q) => Math.min(product.stockQty, q + 1))} disabled={qty >= product.stockQty}>+</button>
            </div>
            <button className="btn btn-lg cart-cta" style={{ flex: 1 }} onClick={addToCart}>
              <span className="cart-cta-label">Savatga qo'shish</span>
              <span className="cart-cta-price">{formatSom(product.price * qty)}</span>
            </button>
          </div>
        </div>
      )}
    </>
  );
}
