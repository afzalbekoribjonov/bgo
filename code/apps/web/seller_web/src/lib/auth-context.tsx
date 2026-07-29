'use client';

import { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { clearToken, decodeToken, getToken } from './auth';

interface AuthState {
  ready: boolean;
  authed: boolean;
  sellerId: string | null;
  sellerType: string | null;
}

interface AuthCtx extends AuthState {
  refresh: () => void;
  logout: () => void;
}

const Ctx = createContext<AuthCtx>({
  ready: false,
  authed: false,
  sellerId: null,
  sellerType: null,
  refresh: () => {},
  logout: () => {},
});

function readState(): AuthState {
  const token = getToken();
  if (!token) return { ready: true, authed: false, sellerId: null, sellerType: null };
  const payload = decodeToken(token);
  if (!payload?.roles?.includes('seller') || !payload.sellerId) {
    clearToken();
    return { ready: true, authed: false, sellerId: null, sellerType: null };
  }
  return {
    ready: true,
    authed: true,
    sellerId: payload.sellerId,
    sellerType: payload.sellerType ?? null,
  };
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({
    ready: false,
    authed: false,
    sellerId: null,
    sellerType: null,
  });

  useEffect(() => {
    setState(readState());
  }, []);

  const refresh = useCallback(() => setState(readState()), []);

  const logout = useCallback(() => {
    clearToken();
    setState({ ready: true, authed: false, sellerId: null, sellerType: null });
  }, []);

  return (
    <Ctx.Provider value={{ ...state, refresh, logout }}>{children}</Ctx.Provider>
  );
}

export function useAuthState() {
  return useContext(Ctx);
}
