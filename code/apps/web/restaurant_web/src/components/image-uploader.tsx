'use client';

import { useRef, useState } from 'react';
import { uploadMenuItemImage } from '@/lib/api';

/**
 * Bitta rasm yuklovchi (taom rasmi yoki oshxona logotipi) — bosish yoki
 * sudrab tashlash, preview va o'chirish. Rasm tanlanmasa joriy (fallback)
 * ko'rinishida qoladi. `upload`/`label`/`shape` — logotip kabi boshqa
 * kontekstlarda qayta ishlatish uchun (standart qiymatlar taom rasmiga mos).
 */
export default function ImageUploader({
  value,
  onChange,
  upload = uploadMenuItemImage,
  label = 'Taom rasmi (ixtiyoriy)',
  shape = 'rect',
}: {
  value: string | null;
  onChange: (url: string | null) => void;
  upload?: (file: File) => Promise<string>;
  label?: string;
  shape?: 'rect' | 'circle';
}) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [drag, setDrag] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleFile(file: File | undefined) {
    if (!file || !file.type.startsWith('image/')) return;
    setError('');
    setLoading(true);
    try {
      onChange(await upload(file));
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
      if (fileRef.current) fileRef.current.value = '';
    }
  }

  if (value) {
    return (
      <div className={`uploader-preview ${shape === 'circle' ? 'round' : ''}`}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={value} alt={label} />
        <button
          type="button"
          className="uploader-rm"
          aria-label="Rasmni o'chirish"
          onClick={() => onChange(null)}
        >
          ✕
        </button>
      </div>
    );
  }

  return (
    <div>
      <div
        className={`uploader-drop ${drag ? 'drag' : ''}`}
        role="button"
        tabIndex={0}
        onClick={() => fileRef.current?.click()}
        onKeyDown={(e) => {
          if (e.key === 'Enter') fileRef.current?.click();
        }}
        onDragOver={(e) => {
          e.preventDefault();
          setDrag(true);
        }}
        onDragLeave={() => setDrag(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDrag(false);
          handleFile(e.dataTransfer.files?.[0]);
        }}
      >
        {loading ? (
          <div className="uploader-progress">
            <div className="uploader-spinner" />
            Yuklanmoqda…
          </div>
        ) : (
          <>
            <div className="uploader-drop-icon">📸</div>
            <div className="uploader-drop-title">{label}</div>
            <div className="uploader-drop-sub">
              Bosing yoki faylni shu yerga tashlang · 5 MB gacha
            </div>
          </>
        )}
      </div>
      <input
        ref={fileRef}
        type="file"
        accept="image/*"
        style={{ display: 'none' }}
        onChange={(e) => handleFile(e.target.files?.[0])}
      />
      {error && (
        <div
          style={{
            marginTop: 8,
            color: 'var(--red)',
            fontSize: 12.5,
            fontWeight: 600,
          }}
        >
          ⚠ {error}
        </div>
      )}
    </div>
  );
}
