'use client';

import { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { getRestaurant, setRestaurantOpen } from '@/lib/api';
import type { Restaurant } from '@/lib/types';

interface RestaurantCtx {
  restaurant: Restaurant | null;
  busy: boolean;
  toggle: () => Promise<void>;
  refresh: () => Promise<void>;
}

const Ctx = createContext<RestaurantCtx>({
  restaurant: null,
  busy: false,
  toggle: async () => {},
  refresh: async () => {},
});

export function useRestaurant() {
  return useContext(Ctx);
}

export function RestaurantProvider({
  id,
  children,
}: {
  id: string;
  children: React.ReactNode;
}) {
  const [restaurant, setRestaurant] = useState<Restaurant | null>(null);
  const [busy, setBusy] = useState(false);

  const refresh = useCallback(async () => {
    try {
      setRestaurant(await getRestaurant(id));
    } catch {
      /* ignore */
    }
  }, [id]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  async function toggle() {
    if (!restaurant || busy) return;
    setBusy(true);
    try {
      setRestaurant(await setRestaurantOpen(id, !restaurant.isOpen));
    } catch {
      /* ignore */
    } finally {
      setBusy(false);
    }
  }

  return (
    <Ctx.Provider value={{ restaurant, busy, toggle, refresh }}>
      {children}
    </Ctx.Provider>
  );
}
