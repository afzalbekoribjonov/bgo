'use client';

import { createContext, useCallback, useContext, useState } from 'react';

interface ConfirmOpts {
  title?: string;
  danger?: boolean;
  confirmLabel?: string;
}
interface DialogState extends ConfirmOpts {
  message: string;
  resolve: (v: boolean) => void;
}

interface DialogCtx {
  confirm: (message: string, opts?: ConfirmOpts) => Promise<boolean>;
}

const Ctx = createContext<DialogCtx>({ confirm: () => Promise.resolve(false) });

export function DialogProvider({ children }: { children: React.ReactNode }) {
  const [dlg, setDlg] = useState<DialogState | null>(null);

  const confirm = useCallback((message: string, opts?: ConfirmOpts) => {
    return new Promise<boolean>((resolve) => {
      setDlg({ message, resolve, ...opts });
    });
  }, []);

  function close(result: boolean) {
    dlg?.resolve(result);
    setDlg(null);
  }

  return (
    <Ctx.Provider value={{ confirm }}>
      {children}
      {dlg && (
        <div className="dialog-overlay" onClick={() => close(false)}>
          <div className="dialog-box" onClick={(e) => e.stopPropagation()}>
            <div className="dialog-title">{dlg.title ?? 'Tasdiqlash'}</div>
            <div className="dialog-msg">{dlg.message}</div>
            <div className="dialog-actions">
              <button className="btn ghost" onClick={() => close(false)}>
                Bekor qilish
              </button>
              <button
                className={`btn ${dlg.danger ? 'red' : ''}`}
                onClick={() => close(true)}
              >
                {dlg.confirmLabel ?? (dlg.danger ? "O'chirish" : 'Tasdiqlash')}
              </button>
            </div>
          </div>
        </div>
      )}
    </Ctx.Provider>
  );
}

export function useDialog() {
  return useContext(Ctx);
}
