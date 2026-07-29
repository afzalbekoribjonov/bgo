'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createOrder, formatSom, getPickupLocations } from '@/lib/api';
import { useToast } from '@/components/toast';
import { useAuthState } from '@/lib/auth-context';
import { useCart } from '@/lib/cart';
import type { PickupLocation } from '@/lib/types';

type Method = 'DELIVERY' | 'PICKUP';

export default function CheckoutPage() {
  const router = useRouter();
  const toast = useToast();
  const { ready, authed } = useAuthState();
  const cart = useCart();

  const [locations, setLocations] = useState<PickupLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [method, setMethod] = useState<Method>('DELIVERY');
  const [locationId, setLocationId] = useState('');
  const [addressText, setAddressText] = useState('');
  const [coords, setCoords] = useState<{ lat: number; lng: number } | null>(null);
  const [locating, setLocating] = useState(false);
  const [placing, setPlacing] = useState(false);
  const [formErr, setFormErr] = useState('');
  const placedRef = useRef(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const locs = await getPickupLocations();
      setLocations(locs);
      if (locs[0]) setLocationId(locs[0].id);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    if (ready && authed) load();
  }, [ready, authed, load]);

  useEffect(() => {
    if (ready && !placedRef.current && cart.items.length === 0) router.replace('/cart');
  }, [ready, cart.items.length, router]);

  function locateMe() {
    if (!navigator.geolocation) {
      toast('Brauzeringiz joylashuvni aniqlay olmaydi', 'error');
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setCoords({ lat: pos.coords.latitude, lng: pos.coords.longitude });
        setLocating(false);
        toast('Joylashuv aniqlandi', 'success');
      },
      () => {
        setLocating(false);
        toast('Joylashuvni aniqlab bo\'lmadi — ruxsat bering', 'error');
      },
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  async function place() {
    setFormErr('');
    if (!locationId) { setFormErr("Olib ketish/yetkazish bazasini tanlang"); return; }
    if (method === 'DELIVERY') {
      if (!coords) { setFormErr("Yetkazish uchun joriy joylashuvni aniqlang"); return; }
      if (!addressText.trim()) { setFormErr("Manzil izohini kiriting (masalan: uy raqami, mo'ljal)"); return; }
    }
    setPlacing(true);
    try {
      const order = await createOrder({
        pickupLocationId: locationId,
        deliveryMethod: method,
        address: method === 'DELIVERY' && coords
          ? { text: addressText.trim(), lat: coords.lat, lng: coords.lng }
          : undefined,
        items: cart.items.map((i) => ({
          productId: i.productId,
          qty: i.qty,
          ...(i.size ? { size: i.size } : {}),
        })),
      });
      placedRef.current = true;
      cart.clear();
      toast('Buyurtma qabul qilindi!', 'success');
      router.replace(`/orders/${order.id}`);
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setPlacing(false);
    }
  }

  if (!ready) return null;

  if (!authed) {
    return (
      <>
        <div className="topbar">
          <button className="topbar-back" onClick={() => router.back()}>←</button>
          <span className="topbar-title">Rasmiylashtirish</span>
        </div>
        <div className="content">
          <div className="empty">
            <div className="empty-icon">🔒</div>
            <div className="empty-title">Buyurtma berish uchun ilovadan oching</div>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <div className="topbar">
        <button className="topbar-back" onClick={() => router.back()}>←</button>
        <span className="topbar-title">Rasmiylashtirish</span>
      </div>
      <div className="content" style={{ paddingBottom: 120 }}>
        <div className="section-title">Qanday olasiz?</div>
        <div className="method-row">
          <div
            className={`method-card ${method === 'DELIVERY' ? 'active' : ''}`}
            onClick={() => setMethod('DELIVERY')}
          >
            <div className="icon">🚗</div>
            <div className="label">Yetkazib berish</div>
          </div>
          <div
            className={`method-card ${method === 'PICKUP' ? 'active' : ''}`}
            onClick={() => setMethod('PICKUP')}
          >
            <div className="icon">🏬</div>
            <div className="label">Olib ketish</div>
          </div>
        </div>

        {loading ? (
          <div className="sk sk-line" style={{ height: 44 }} />
        ) : (
          <div className="field">
            <label>{method === 'DELIVERY' ? "Qaysi ombordan yetkazilsin" : "Qaysi joydan olib ketasiz"}</label>
            <select value={locationId} onChange={(e) => setLocationId(e.target.value)}>
              {locations.map((l) => (
                <option key={l.id} value={l.id}>{l.name} — {l.address}</option>
              ))}
            </select>
          </div>
        )}

        {method === 'DELIVERY' && (
          <>
            <div className="field">
              <label>Yetkazish manzili</label>
              <button className="btn ghost btn-block" onClick={locateMe} disabled={locating}>
                {locating ? 'Aniqlanmoqda...' : coords ? '📍 Joylashuv aniqlandi — qayta aniqlash' : '📍 Joriy joylashuvni aniqlash'}
              </button>
            </div>
            <div className="field">
              <label>Mo'ljal / uy raqami</label>
              <input
                value={addressText}
                onChange={(e) => setAddressText(e.target.value)}
                placeholder="Masalan: 5-uy, ko'k darvoza"
              />
            </div>
          </>
        )}

        {formErr && <div className="err-block">{formErr}</div>}

        <div className="divider" />
        <div className="section-title">Buyurtma</div>
        <div className="card card-p">
          {cart.items.map((i) => (
            <div key={`${i.productId}__${i.size ?? ''}`} className="summary-row">
              <span>
                {i.name}
                {i.size && <span className="size-tag">{i.size}</span>} ×{i.qty}
              </span>
              <span>{formatSom(i.price * i.qty)}</span>
            </div>
          ))}
          <div className="summary-row total">
            <span>Jami (mahsulotlar)</span>
            <span>{formatSom(cart.total)}</span>
          </div>
          <div className="text-xs muted" style={{ marginTop: 6 }}>
            {method === 'DELIVERY' ? "Yetkazish narxi masofaga qarab hisoblanadi va buyurtma tasdiqlangach ko'rsatiladi" : "Olib ketishda qo'shimcha to'lov yo'q"}
          </div>
        </div>
      </div>

      <div className="fixed-cta">
        <button className="btn btn-block" disabled={placing} onClick={place}>
          {placing ? 'Yuborilmoqda...' : 'Buyurtma berish'}
        </button>
      </div>
    </>
  );
}
