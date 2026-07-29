'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { consumeUrlToken, hasToken } from './auth';

const Ctx = createContext<{ ready: boolean; authed: boolean }>({ ready: false, authed: false });

/** Ilova ochilganda ?token= ni o'qiydi va butun daraxtga "kirilganmi" holatini beradi. */
export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState({ ready: false, authed: false });

  useEffect(() => {
    consumeUrlToken();
    setState({ ready: true, authed: hasToken() });
  }, []);

  return <Ctx.Provider value={state}>{children}</Ctx.Provider>;
}

export function useAuthState() {
  return useContext(Ctx);
}
