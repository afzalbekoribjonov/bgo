'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  addGeoPlace,
  createGeoArea,
  deleteGeoArea,
  deleteGeoPlace,
  getGeoAreas,
  updateGeoArea,
} from '@/lib/api';
import type { ServiceArea } from '@/lib/types';

/** To'rtburchak (bounding box) → GeoJSON poligon. */
function bboxToPolygon(
  minLat: number,
  maxLat: number,
  minLng: number,
  maxLng: number,
): number[][][] {
  return [
    [
      [minLng, minLat],
      [maxLng, minLat],
      [maxLng, maxLat],
      [minLng, maxLat],
      [minLng, minLat],
    ],
  ];
}

export default function GeoPage() {
  const [areas, setAreas] = useState<ServiceArea[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  // Yangi hudud (to'rtburchak chegara orqali)
  const [name, setName] = useState('');
  const [minLat, setMinLat] = useState('');
  const [maxLat, setMaxLat] = useState('');
  const [minLng, setMinLng] = useState('');
  const [maxLng, setMaxLng] = useState('');

  const load = useCallback(async () => {
    try {
      setAreas(await getGeoAreas());
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function addArea() {
    const a = parseFloat(minLat);
    const b = parseFloat(maxLat);
    const c = parseFloat(minLng);
    const d = parseFloat(maxLng);
    if (!name.trim() || [a, b, c, d].some((n) => Number.isNaN(n))) {
      setError('Nom va 4 ta koordinata to‘g‘ri kiritilishi shart');
      return;
    }
    setBusy('new');
    try {
      await createGeoArea({
        name: name.trim(),
        centerLat: (a + b) / 2,
        centerLng: (c + d) / 2,
        boundary: bboxToPolygon(a, b, c, d),
        isActive: true,
      });
      setName('');
      setMinLat('');
      setMaxLat('');
      setMinLng('');
      setMaxLng('');
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(null);
    }
  }

  async function toggleActive(area: ServiceArea) {
    setBusy(area.id);
    try {
      await updateGeoArea(area.id, { isActive: !area.isActive });
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(null);
    }
  }

  async function removeArea(area: ServiceArea) {
    if (!window.confirm(`"${area.name}" hududini (va barcha joylarini) o'chirasizmi?`)) return;
    setBusy(area.id);
    try {
      await deleteGeoArea(area.id);
      await load();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="container">
      <h1 className="h1">Xizmat hududlari</h1>
      <p className="muted" style={{ marginBottom: 12 }}>
        Tuman chegarasi (to‘rtburchak) va joylar (markerlar). Mijoz ilovasi shu
        joylarni ko‘rsatadi. Aniq chegara keyin xarita orqali tahrirlanadi.
      </p>
      {error && <p className="error">{error}</p>}

      <div className="card" style={{ maxWidth: 760 }}>
        <strong>Yangi hudud (tuman)</strong>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8, alignItems: 'end' }}>
          <div>
            <label>Nomi</label>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Beshariq tumani" />
          </div>
          <div>
            <label>Lat (min)</label>
            <input value={minLat} onChange={(e) => setMinLat(e.target.value)} placeholder="40.36" />
          </div>
          <div>
            <label>Lat (max)</label>
            <input value={maxLat} onChange={(e) => setMaxLat(e.target.value)} placeholder="40.52" />
          </div>
          <div>
            <label>Lng (min)</label>
            <input value={minLng} onChange={(e) => setMinLng(e.target.value)} placeholder="70.52" />
          </div>
          <div>
            <label>Lng (max)</label>
            <input value={maxLng} onChange={(e) => setMaxLng(e.target.value)} placeholder="70.74" />
          </div>
          <button className="btn" disabled={busy === 'new'} onClick={addArea}>
            Qo&apos;shish
          </button>
        </div>
      </div>

      {areas.length === 0 && !error && <p className="empty">Hudud yo&apos;q</p>}

      {areas.map((area) => (
        <AreaCard
          key={area.id}
          area={area}
          busy={busy === area.id}
          onToggle={() => toggleActive(area)}
          onDelete={() => removeArea(area)}
          onChanged={load}
        />
      ))}
    </div>
  );
}

function AreaCard({
  area,
  busy,
  onToggle,
  onDelete,
  onChanged,
}: {
  area: ServiceArea;
  busy: boolean;
  onToggle: () => void;
  onDelete: () => void;
  onChanged: () => Promise<void>;
}) {
  const [label, setLabel] = useState('');
  const [lat, setLat] = useState('');
  const [lng, setLng] = useState('');
  const [adding, setAdding] = useState(false);

  async function addPlace() {
    const la = parseFloat(lat);
    const ln = parseFloat(lng);
    if (!label.trim() || Number.isNaN(la) || Number.isNaN(ln)) return;
    setAdding(true);
    try {
      await addGeoPlace(area.id, { label: label.trim(), lat: la, lng: ln });
      setLabel('');
      setLat('');
      setLng('');
      await onChanged();
    } finally {
      setAdding(false);
    }
  }

  async function removePlace(id: string) {
    await deleteGeoPlace(id);
    await onChanged();
  }

  return (
    <div className="card">
      <div className="row" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <strong>{area.name}</strong>{' '}
          <span
            className="badge"
            style={{ background: area.isActive ? '#2e7d32' : '#9e9e9e' }}
          >
            {area.isActive ? 'Faol' : 'Nofaol'}
          </span>
          <div className="muted" style={{ fontSize: 12 }}>
            markaz: {area.centerLat.toFixed(4)}, {area.centerLng.toFixed(4)} · {area.places.length} joy
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn ghost" disabled={busy} onClick={onToggle}>
            {area.isActive ? 'Nofaol qilish' : 'Faollashtirish'}
          </button>
          <button className="btn red" disabled={busy} onClick={onDelete}>
            O&apos;chirish
          </button>
        </div>
      </div>

      <div style={{ marginTop: 10, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
        {area.places.map((p) => (
          <span
            key={p.id}
            className="badge"
            style={{ background: 'var(--surface-2, #eee)', color: '#333', cursor: 'pointer' }}
            title="O'chirish uchun bosing"
            onClick={() => removePlace(p.id)}
          >
            📍 {p.label} ✕
          </span>
        ))}
        {area.places.length === 0 && <span className="muted">Joy yo&apos;q</span>}
      </div>

      <div style={{ display: 'flex', gap: 8, marginTop: 10, alignItems: 'end', flexWrap: 'wrap' }}>
        <div>
          <label>Joy nomi</label>
          <input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Markaziy bozor" />
        </div>
        <div>
          <label>Lat</label>
          <input value={lat} onChange={(e) => setLat(e.target.value)} placeholder="40.4236" />
        </div>
        <div>
          <label>Lng</label>
          <input value={lng} onChange={(e) => setLng(e.target.value)} placeholder="70.6094" />
        </div>
        <button className="btn ghost" disabled={adding} onClick={addPlace}>
          Joy qo&apos;shish
        </button>
      </div>
    </div>
  );
}
