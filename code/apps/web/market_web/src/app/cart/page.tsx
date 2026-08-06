'use client';

import { useRouter } from 'next/navigation';
import { formatSom } from '@/lib/api';
import { useAuthState } from '@/lib/auth-context';
import { lineKey, useCart } from '@/lib/cart';
import { useDialog } from '@/components/dialog';
import Topbar from '@/components/topbar';
import QtyStepper from '@/components/qty-stepper';

export default function CartPage() {
  const router = useRouter();
  const { authed, ready } = useAuthState();
  const cart = useCart();
  const dialog = useDialog();

  async function removeItem(key: string, name: string, size?: string) {
    const label = size ? `"${name}" (${size})` : `"${name}"`;
    const ok = await dialog.confirm(`${label}ni savatdan olib tashlaysizmi?`, { danger: true, confirmLabel: "Olib tashlash" });
    if (ok) cart.remove(key);
  }

  if (!ready) return null;

  return (
    <>
      <Topbar title="🛒 Savat" />
      <div className="content" style={{ paddingBottom: cart.items.length ? 140 : 20 }}>
        {!authed && (
          <div className="view-only-banner">
            👀 Buyurtma berish uchun ilovadan oching
          </div>
        )}

        {cart.items.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">🛒</div>
            <div className="empty-title">Savat bo'sh</div>
            <div className="empty-desc" style={{ marginBottom: 16 }}>Mahsulot qo'shish uchun katalogga o'ting</div>
            <button className="btn" onClick={() => router.push('/')}>Katalogga o'tish</button>
          </div>
        ) : (
          <div className="card card-p">
            {cart.items.map((item) => {
              const key = lineKey(item.productId, item.size);
              return (
                <div key={key} className="cart-item">
                  <div className="cart-item-img">
                    {item.imageUrl ? <img src={item.imageUrl} alt={item.name} /> : '🛒'}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div className="cart-item-name">
                      {item.name}
                      {item.size && <span className="size-tag">{item.size}</span>}
                    </div>
                    <div className="cart-item-price">{formatSom(item.price)}</div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
                    <QtyStepper
                      value={item.qty}
                      onDecrement={() => cart.setQty(key, item.qty - 1)}
                      onIncrement={() => cart.setQty(key, item.qty + 1)}
                      incrementDisabled={item.qty >= item.stockQty}
                    />
                    <button
                      className="text-xs"
                      style={{ background: 'none', border: 'none', color: 'var(--red)', cursor: 'pointer' }}
                      onClick={() => removeItem(key, item.name, item.size)}
                    >
                      O'chirish
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {cart.items.length > 0 && (
        <div className="fixed-cta">
          <div className="card card-p">
            <div className="summary-row total">
              <span>Jami</span>
              <span>{formatSom(cart.total)}</span>
            </div>
            <button
              className="btn btn-block"
              style={{ marginTop: 10 }}
              disabled={!authed}
              onClick={() => router.push('/checkout')}
            >
              {authed ? "Rasmiylashtirish" : 'Ilovadan oching'}
            </button>
          </div>
        </div>
      )}
    </>
  );
}
