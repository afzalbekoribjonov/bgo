'use client';

import {
  createContext,
  useCallback,
  useContext,
  useRef,
  useState,
} from 'react';

/* ---- Types ---- */
type ConfirmDlg = {
  kind: 'confirm';
  title?: string;
  message: string;
  danger?: boolean;
  /** Tasdiqlash tugmasi matni — berilmasa danger uchun "O'chirish". */
  confirmLabel?: string;
  resolve: (v: boolean) => void;
};
type PromptDlg = {
  kind: 'prompt';
  title?: string;
  message: string;
  initial?: string;
  placeholder?: string;
  resolve: (v: string | null) => void;
};
type AlertDlg = {
  kind: 'alert';
  title?: string;
  message: string;
  codeValue?: string;
  resolve: () => void;
};

type AnyDlg = ConfirmDlg | PromptDlg | AlertDlg;

interface DialogCtx {
  confirm: (
    message: string,
    opts?: { title?: string; danger?: boolean; confirmLabel?: string },
  ) => Promise<boolean>;
  prompt: (message: string, opts?: { title?: string; initial?: string; placeholder?: string }) => Promise<string | null>;
  alert: (message: string, opts?: { title?: string; code?: string }) => Promise<void>;
}

/* ---- Context ---- */
const Ctx = createContext<DialogCtx>({
  confirm: () => Promise.resolve(false),
  prompt: () => Promise.resolve(null),
  alert: () => Promise.resolve(),
});

/* ---- Provider ---- */
export function DialogProvider({ children }: { children: React.ReactNode }) {
  const [dlg, setDlg] = useState<AnyDlg | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const confirm = useCallback(
    (message: string, opts?: { title?: string; danger?: boolean; confirmLabel?: string }) => {
      return new Promise<boolean>((resolve) => {
        setDlg({
          kind: 'confirm',
          message,
          title: opts?.title,
          danger: opts?.danger,
          confirmLabel: opts?.confirmLabel,
          resolve,
        });
      });
    },
    [],
  );

  const prompt = useCallback(
    (message: string, opts?: { title?: string; initial?: string; placeholder?: string }) => {
      return new Promise<string | null>((resolve) => {
        setDlg({
          kind: 'prompt',
          message,
          title: opts?.title,
          initial: opts?.initial ?? '',
          placeholder: opts?.placeholder,
          resolve,
        });
      });
    },
    [],
  );

  const alert = useCallback((message: string, opts?: { title?: string; code?: string }) => {
    return new Promise<void>((resolve) => {
      setDlg({ kind: 'alert', message, title: opts?.title, codeValue: opts?.code, resolve });
    });
  }, []);

  function close() {
    if (!dlg) return;
    if (dlg.kind === 'confirm') dlg.resolve(false);
    else if (dlg.kind === 'prompt') dlg.resolve(null);
    else dlg.resolve();
    setDlg(null);
  }

  function accept() {
    if (!dlg) return;
    if (dlg.kind === 'confirm') {
      dlg.resolve(true);
    } else if (dlg.kind === 'prompt') {
      dlg.resolve(inputRef.current?.value ?? null);
    } else {
      dlg.resolve();
    }
    setDlg(null);
  }

  return (
    <Ctx.Provider value={{ confirm, prompt, alert }}>
      {children}
      {dlg && (
        <div
          className="dialog-overlay"
          onClick={close}
          onKeyDown={(e) => { if (e.key === 'Escape') close(); }}
        >
          <div className="dialog-box" onClick={(e) => e.stopPropagation()}>
            {/* Icon */}
            {dlg.kind === 'confirm' && (
              <div className={`dialog-icon ${dlg.danger ? 'red' : 'amber'}`}>
                {dlg.danger ? '🗑️' : '⚠️'}
              </div>
            )}
            {dlg.kind === 'prompt' && <div className="dialog-icon blue">✏️</div>}
            {dlg.kind === 'alert' && <div className="dialog-icon green">ℹ️</div>}

            {/* Title */}
            <div className="dialog-title">
              {dlg.title ??
                (dlg.kind === 'confirm'
                  ? "Tasdiqlash"
                  : dlg.kind === 'prompt'
                  ? "Qiymat kiriting"
                  : "Natija")}
            </div>

            {/* Message */}
            <div className="dialog-msg">{dlg.message}</div>

            {/* Alert: code display */}
            {dlg.kind === 'alert' && dlg.codeValue && (
              <div className="dialog-result">
                <span className="dialog-code">{dlg.codeValue}</span>
              </div>
            )}

            {/* Prompt: text input */}
            {dlg.kind === 'prompt' && (
              <div style={{ marginBottom: 20 }}>
                <label className="dialog-input-label">Qiymat</label>
                <input
                  ref={inputRef}
                  defaultValue={dlg.initial ?? ''}
                  placeholder={dlg.placeholder ?? ''}
                  onKeyDown={(e) => { if (e.key === 'Enter') accept(); }}
                  autoFocus
                  style={{ width: '100%' }}
                />
              </div>
            )}

            {/* Actions */}
            <div className="dialog-actions">
              {dlg.kind !== 'alert' && (
                <button className="btn ghost" onClick={close}>
                  Bekor qilish
                </button>
              )}
              <button
                className={`btn ${dlg.kind === 'confirm' && dlg.danger ? 'red' : ''}`}
                onClick={accept}
                autoFocus={dlg.kind !== 'prompt'}
              >
                {dlg.kind === 'confirm'
                  ? dlg.confirmLabel ?? (dlg.danger ? "O'chirish" : 'Tasdiqlash')
                  : dlg.kind === 'prompt'
                  ? 'Saqlash'
                  : 'Yopish'}
              </button>
            </div>
          </div>
        </div>
      )}
    </Ctx.Provider>
  );
}

/* ---- Hook ---- */
export function useDialog() {
  return useContext(Ctx);
}
