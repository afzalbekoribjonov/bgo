'use client';

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';

export interface CartItem {
  productId: string;
  name: string;
  price: number;
  imageUrl: string | null;
  stockQty: number;
  qty: number;
  /** Tanlangan o'lcham — o'lchamsiz mahsulotda yo'q. */
  size?: string;
}

/**
 * Savat qatorining kaliti: bir xil mahsulotning turli o'lchamlari — alohida
 * qatorlar (masalan futbolka M va futbolka L).
 */
export function lineKey(productId: string, size?: string): string {
  return `${productId}__${size ?? ''}`;
}

interface CartCtx {
  items: CartItem[];
  count: number;
  total: number;
  add: (item: Omit<CartItem, 'qty'>, qty?: number) => void;
  setQty: (key: string, qty: number) => void;
  remove: (key: string) => void;
  clear: () => void;
}

const STORAGE_KEY = 'market_cart';

const Ctx = createContext<CartCtx>({
  items: [],
  count: 0,
  total: 0,
  add: () => {},
  setQty: () => {},
  remove: () => {},
  clear: () => {},
});

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) setItems(JSON.parse(raw));
    } catch {
      /* ignore */
    }
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
  }, [items, hydrated]);

  const add = useCallback((item: Omit<CartItem, 'qty'>, qty = 1) => {
    const key = lineKey(item.productId, item.size);
    setItems((prev) => {
      const existing = prev.find((i) => lineKey(i.productId, i.size) === key);
      if (existing) {
        return prev.map((i) =>
          lineKey(i.productId, i.size) === key
            ? { ...i, qty: Math.min(i.qty + qty, item.stockQty) }
            : i,
        );
      }
      return [...prev, { ...item, qty: Math.min(qty, item.stockQty) }];
    });
  }, []);

  const setQty = useCallback((key: string, qty: number) => {
    setItems((prev) =>
      qty <= 0
        ? prev.filter((i) => lineKey(i.productId, i.size) !== key)
        : prev.map((i) => (lineKey(i.productId, i.size) === key ? { ...i, qty } : i)),
    );
  }, []);

  const remove = useCallback((key: string) => {
    setItems((prev) => prev.filter((i) => lineKey(i.productId, i.size) !== key));
  }, []);

  const clear = useCallback(() => setItems([]), []);

  const count = useMemo(() => items.reduce((s, i) => s + i.qty, 0), [items]);
  const total = useMemo(() => items.reduce((s, i) => s + i.qty * i.price, 0), [items]);

  return (
    <Ctx.Provider value={{ items, count, total, add, setQty, remove, clear }}>
      {children}
    </Ctx.Provider>
  );
}

export function useCart() {
  return useContext(Ctx);
}
