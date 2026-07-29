'use client';

import { useRef, useState } from 'react';

/**
 * Zamonaviy rasm yuklovchi: bosish yoki sudrab tashlash (drag&drop),
 * bir nechta fayl birdan, preview to'ri, tartiblash (◀ ▶) va o'chirish.
 * Birinchi rasm — asosiy (katalog kartasida ko'rinadi).
 */
export default function ImageUploader({
  value,
  onChange,
  upload,
  emptyIcon = '🖼️',
}: {
  value: string[];
  onChange: (urls: string[]) => void;
  /** Bitta faylni yuklab URL qaytaradigan funksiya (api.ts'dan). */
  upload: (file: File) => Promise<string>;
  emptyIcon?: string;
}) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [drag, setDrag] = useState(false);
  const [progress, setProgress] = useState<{ done: number; total: number } | null>(null);
  const [error, setError] = useState('');

  async function handleFiles(files: FileList | File[]) {
    const list = [...files].filter((f) => f.type.startsWith('image/'));
    if (list.length === 0) return;
    setError('');
    setProgress({ done: 0, total: list.length });
    const added: string[] = [];
    for (let i = 0; i < list.length; i++) {
      try {
        added.push(await upload(list[i]));
      } catch (e) {
        setError((e as Error).message);
      }
      setProgress({ done: i + 1, total: list.length });
    }
    if (added.length > 0) onChange([...value, ...added]);
    setProgress(null);
    if (fileRef.current) fileRef.current.value = '';
  }

  function move(i: number, dir: -1 | 1) {
    const j = i + dir;
    if (j < 0 || j >= value.length) return;
    const next = [...value];
    [next[i], next[j]] = [next[j], next[i]];
    onChange(next);
  }

  return (
    <div className="uploader">
      {value.length > 0 && (
        <div className="uploader-grid">
          {value.map((url, i) => (
            <div key={`${url}-${i}`} className="uploader-thumb">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={url} alt={`Rasm ${i + 1}`} />
              {i === 0 && <span className="uploader-main">Asosiy</span>}
              <button
                type="button"
                className="uploader-rm"
                aria-label="Rasmni o'chirish"
                onClick={() => onChange(value.filter((_, idx) => idx !== i))}
              >
                ✕
              </button>
              <div className="uploader-mv">
                <button type="button" aria-label="Chapga" disabled={i === 0} onClick={() => move(i, -1)}>◀</button>
                <button type="button" aria-label="O'ngga" disabled={i === value.length - 1} onClick={() => move(i, 1)}>▶</button>
              </div>
            </div>
          ))}
        </div>
      )}

      <div
        className={`uploader-drop ${drag ? 'drag' : ''}`}
        role="button"
        tabIndex={0}
        onClick={() => fileRef.current?.click()}
        onKeyDown={(e) => { if (e.key === 'Enter') fileRef.current?.click(); }}
        onDragOver={(e) => { e.preventDefault(); setDrag(true); }}
        onDragLeave={() => setDrag(false)}
        onDrop={(e) => { e.preventDefault(); setDrag(false); handleFiles(e.dataTransfer.files); }}
      >
        {progress ? (
          <div className="uploader-progress">
            <div className="uploader-spinner" />
            Yuklanmoqda… {progress.done}/{progress.total}
          </div>
        ) : (
          <>
            <div className="uploader-drop-icon">{emptyIcon}</div>
            <div className="uploader-drop-title">Rasm yuklash</div>
            <div className="uploader-drop-sub">Bosing yoki faylni shu yerga tashlang · JPG/PNG/WebP · 5 MB gacha</div>
          </>
        )}
      </div>

      <input
        ref={fileRef}
        type="file"
        accept="image/*"
        multiple
        style={{ display: 'none' }}
        onChange={(e) => { if (e.target.files?.length) handleFiles(e.target.files); }}
      />

      {error && <div className="err-block" style={{ marginTop: 8 }}>{error}</div>}
    </div>
  );
}
