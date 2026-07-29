'use client';

import { useState } from 'react';

/** Tez tanlash uchun keng tarqalgan o'lcham to'plamlari. */
const PRESETS: { label: string; sizes: string[] }[] = [
  { label: 'Kiyim (S–XXL)', sizes: ['S', 'M', 'L', 'XL', 'XXL'] },
  { label: 'Oyoq kiyim (36–45)', sizes: ['36', '37', '38', '39', '40', '41', '42', '43', '44', '45'] },
  { label: 'Bolalar (2–12 yosh)', sizes: ['2', '4', '6', '8', '10', '12'] },
];

/**
 * O'lcham muharriri — chip ko'rinishida. Bo'sh qoldirilsa mahsulot
 * o'lchamsiz hisoblanadi va mijozdan o'lcham so'ralmaydi.
 */
export default function SizeEditor({
  value,
  onChange,
}: {
  value: string[];
  onChange: (sizes: string[]) => void;
}) {
  const [input, setInput] = useState('');

  function add(raw: string) {
    const parts = raw
      .split(/[,،\s]+/)
      .map((s) => s.trim())
      .filter(Boolean);
    if (parts.length === 0) return;
    const next = [...value];
    for (const p of parts) {
      if (!next.some((s) => s.toLowerCase() === p.toLowerCase())) next.push(p);
    }
    onChange(next);
    setInput('');
  }

  function remove(size: string) {
    onChange(value.filter((s) => s !== size));
  }

  function applyPreset(sizes: string[]) {
    const next = [...value];
    for (const p of sizes) {
      if (!next.some((s) => s.toLowerCase() === p.toLowerCase())) next.push(p);
    }
    onChange(next);
  }

  return (
    <div>
      {value.length > 0 && (
        <div className="size-chip-row" style={{ marginBottom: 10 }}>
          {value.map((s) => (
            <span key={s} className="size-chip editable">
              {s}
              <button
                type="button"
                aria-label={`${s} o'lchamini olib tashlash`}
                onClick={() => remove(s)}
              >
                ✕
              </button>
            </span>
          ))}
        </div>
      )}

      <div className="row" style={{ gap: 8, marginBottom: 10 }}>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter' || e.key === ',') {
              e.preventDefault();
              add(input);
            }
          }}
          placeholder="S, M, L yoki 42, 43…"
        />
        <button
          type="button"
          className="btn btn-sm"
          disabled={!input.trim()}
          onClick={() => add(input)}
        >
          Qo'shish
        </button>
      </div>

      <div className="size-chip-row">
        {PRESETS.map((p) => (
          <button
            key={p.label}
            type="button"
            className="preset-chip"
            onClick={() => applyPreset(p.sizes)}
          >
            + {p.label}
          </button>
        ))}
        {value.length > 0 && (
          <button
            type="button"
            className="preset-chip danger"
            onClick={() => onChange([])}
          >
            Tozalash
          </button>
        )}
      </div>

      <div className="text-xs muted" style={{ marginTop: 8 }}>
        Bo'sh qoldirilsa — mahsulot o'lchamsiz sotiladi.
      </div>
    </div>
  );
}
