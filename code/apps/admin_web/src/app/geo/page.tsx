'use client';

import dynamic from 'next/dynamic';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  addGeoPlace,
  addGeoRoad,
  createGeoArea,
  deleteGeoArea,
  deleteGeoPlace,
  deleteGeoRoad,
  getGeoAreas,
  getGeoRoads,
  importOsmRoads,
  updateGeoArea,
} from '@/lib/api';
import {
  ROAD_COLORS,
  ROAD_KIND_LABELS,
  ROAD_KINDS,
} from '@/lib/road-style';
import { PLACE_CATEGORIES, placeCategory } from '@/lib/place-style';
import type { MapRoad, RoadKind, ServiceArea } from '@/lib/types';

// Leaflet faqat brauzerda ishlaydi — SSR'siz dinamik yuklanadi.
const RoadMap = dynamic(() => import('@/components/road-map'), {
  ssr: false,
  loading: () => (
    <div
      className="card"
      style={{
        height: 540,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'var(--muted)',
      }}
    >
      Xarita yuklanmoqda…
    </div>
  ),
});

type LatLng = [number, number];

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
  const [roads, setRoads] = useState<MapRoad[]>([]);
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
      const [a, r] = await Promise.all([getGeoAreas(), getGeoRoads()]);
      setAreas(a);
      setRoads(r);
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
      <h1 className="h1">Xizmat hududlari va navigatsiya</h1>
      <p className="muted" style={{ marginBottom: 16 }}>
        Beshariq xaritasiga har bir ko‘cha va yo‘lni chizing — haydovchilar shu
        qatlam orqali adashmay manzilni topadi. Quyida hududlar va mo‘ljal
        joylarni boshqarasiz.
      </p>
      {error && <p className="error">{error}</p>}

      <MapEditor
        areas={areas}
        roads={roads}
        onChanged={load}
        setError={setError}
      />

      <h2 className="h1" style={{ fontSize: 18, marginTop: 28 }}>
        Hududlar va joylar
      </h2>

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

/** Xarita muharriri — yo'l chizish + joy (oshxona/parkovka/...) belgilash. */
function MapEditor({
  areas,
  roads,
  onChanged,
  setError,
}: {
  areas: ServiceArea[];
  roads: MapRoad[];
  onChanged: () => Promise<void>;
  setError: (m: string | null) => void;
}) {
  const [mode, setMode] = useState<'road' | 'place'>('road');
  const [areaId, setAreaId] = useState('');
  const [saving, setSaving] = useState(false);
  const [importing, setImporting] = useState(false);
  // Yo'l
  const [draft, setDraft] = useState<LatLng[]>([]);
  const [drawing, setDrawing] = useState(false);
  const [roadName, setRoadName] = useState('');
  const [roadKind, setRoadKind] = useState<RoadKind>('street');
  const [selectedRoadId, setSelectedRoadId] = useState<string | null>(null);
  // Joy
  const [placeDraft, setPlaceDraft] = useState<LatLng | null>(null);
  const [placeLabel, setPlaceLabel] = useState('');
  const [placeCat, setPlaceCat] = useState('restaurant');
  const [selectedPlaceId, setSelectedPlaceId] = useState<string | null>(null);

  // Hudud tanlovini birinchi faol hududga sozlash.
  useEffect(() => {
    if (areaId && areas.some((a) => a.id === areaId)) return;
    const first = areas.find((a) => a.isActive) ?? areas[0];
    if (first) setAreaId(first.id);
  }, [areas, areaId]);

  const allPlaces = useMemo(() => areas.flatMap((a) => a.places), [areas]);
  const clickEnabled = mode === 'place' ? true : drawing;

  function onMapClick(lat: number, lng: number) {
    const pt: LatLng = [Number(lat.toFixed(6)), Number(lng.toFixed(6))];
    if (mode === 'road') setDraft((d) => [...d, pt]);
    else setPlaceDraft(pt);
  }

  const undo = () => setDraft((d) => d.slice(0, -1));
  const clearDraft = () => setDraft([]);

  async function saveRoad() {
    if (!areaId) {
      setError('Avval hudud yarating (yo‘l hududga biriktiriladi)');
      return;
    }
    if (draft.length < 2) {
      setError('Yo‘l uchun kamida 2 ta nuqta belgilang');
      return;
    }
    if (!roadName.trim()) {
      setError('Yo‘l nomini kiriting');
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await addGeoRoad(areaId, {
        name: roadName.trim(),
        kind: roadKind,
        points: draft,
      });
      setDraft([]);
      setRoadName('');
      setDrawing(false);
      await onChanged();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function savePlace() {
    if (!areaId) {
      setError('Avval hudud yarating');
      return;
    }
    if (!placeDraft) {
      setError('Xaritani bosib joy nuqtasini belgilang');
      return;
    }
    if (!placeLabel.trim()) {
      setError('Joy nomini kiriting');
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await addGeoPlace(areaId, {
        label: placeLabel.trim(),
        lat: placeDraft[0],
        lng: placeDraft[1],
        category: placeCat,
      });
      setPlaceDraft(null);
      setPlaceLabel('');
      await onChanged();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  async function removeRoad(r: MapRoad) {
    if (!window.confirm(`"${r.name}" yo'lini o'chirasizmi?`)) return;
    setError(null);
    try {
      await deleteGeoRoad(r.id);
      if (selectedRoadId === r.id) setSelectedRoadId(null);
      await onChanged();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  async function removePlace(id: string) {
    if (!window.confirm("Joyni o'chirasizmi?")) return;
    setError(null);
    try {
      await deleteGeoPlace(id);
      if (selectedPlaceId === id) setSelectedPlaceId(null);
      await onChanged();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  async function runImportOsm() {
    if (
      !window.confirm(
        "OSM'dan barcha yo'llar import qilinadi (mavjud yo'llar almashtiriladi). Davom etasizmi?",
      )
    )
      return;
    setImporting(true);
    setError(null);
    try {
      const res = await importOsmRoads();
      await onChanged();
      window.alert(`${res.imported} ta yo'l import qilindi`);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setImporting(false);
    }
  }

  const grouped = useMemo(() => {
    const g: Record<RoadKind, MapRoad[]> = { center: [], main: [], street: [] };
    for (const r of roads) (g[r.kind] ?? g.street).push(r);
    return g;
  }, [roads]);

  return (
    <div className="card">
      <div
        className="row"
        style={{ justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}
      >
        <strong>Xarita muharriri — yo‘llar va joylar</strong>
        <span className="muted" style={{ fontSize: 13 }}>
          {roads.length} yo‘l · {allPlaces.length} joy
        </span>
      </div>

      {/* Rejim tanlash */}
      <div style={{ display: 'flex', gap: 8, marginTop: 12, flexWrap: 'wrap' }}>
        <button
          className={mode === 'road' ? 'btn' : 'btn ghost'}
          onClick={() => setMode('road')}
        >
          🛣️ Yo‘l chizish
        </button>
        <button
          className={mode === 'place' ? 'btn' : 'btn ghost'}
          onClick={() => setMode('place')}
        >
          📍 Joy belgilash
        </button>
        <div style={{ flex: 1 }} />
        <button className="btn ghost" onClick={runImportOsm} disabled={importing}>
          {importing ? 'Import qilinmoqda…' : '⤓ OSM yo‘llarini import'}
        </button>
      </div>

      {/* Asboblar — hudud + rejimga xos */}
      <div
        style={{
          display: 'flex',
          flexWrap: 'wrap',
          gap: 8,
          alignItems: 'end',
          marginTop: 12,
          marginBottom: 6,
        }}
      >
        <div>
          <label>Hudud</label>
          <select value={areaId} onChange={(e) => setAreaId(e.target.value)}>
            {areas.length === 0 && <option value="">— hudud yo‘q —</option>}
            {areas.map((a) => (
              <option key={a.id} value={a.id}>
                {a.name}
                {a.isActive ? '' : ' (nofaol)'}
              </option>
            ))}
          </select>
        </div>

        {mode === 'road' ? (
          <>
            <div>
              <label>Yo‘l nomi</label>
              <input
                value={roadName}
                onChange={(e) => setRoadName(e.target.value)}
                placeholder="Navoiy ko‘chasi"
              />
            </div>
            <div>
              <label>Turi</label>
              <select value={roadKind} onChange={(e) => setRoadKind(e.target.value as RoadKind)}>
                {ROAD_KINDS.map((k) => (
                  <option key={k} value={k}>
                    {ROAD_KIND_LABELS[k]}
                  </option>
                ))}
              </select>
            </div>
            <button
              className={drawing ? 'btn red' : 'btn'}
              onClick={() => setDrawing((v) => !v)}
            >
              {drawing ? 'Chizishni to‘xtatish' : 'Chizishni boshlash'}
            </button>
            <button className="btn ghost" onClick={undo} disabled={draft.length === 0}>
              Oxirgi nuqta ✕
            </button>
            <button className="btn ghost" onClick={clearDraft} disabled={draft.length === 0}>
              Tozalash
            </button>
            <button
              className="btn"
              onClick={saveRoad}
              disabled={saving || draft.length < 2 || !roadName.trim() || !areaId}
            >
              {saving ? 'Saqlanmoqda…' : 'Yo‘lni saqlash'}
            </button>
          </>
        ) : (
          <>
            <div>
              <label>Joy nomi</label>
              <input
                value={placeLabel}
                onChange={(e) => setPlaceLabel(e.target.value)}
                placeholder="Markaziy shifoxona"
              />
            </div>
            <div>
              <label>Turi</label>
              <select value={placeCat} onChange={(e) => setPlaceCat(e.target.value)}>
                {PLACE_CATEGORIES.map((c) => (
                  <option key={c.key} value={c.key}>
                    {c.emoji} {c.label}
                  </option>
                ))}
              </select>
            </div>
            <button
              className="btn ghost"
              onClick={() => setPlaceDraft(null)}
              disabled={!placeDraft}
            >
              Bekor
            </button>
            <button
              className="btn"
              onClick={savePlace}
              disabled={saving || !placeDraft || !placeLabel.trim() || !areaId}
            >
              {saving ? 'Saqlanmoqda…' : 'Joyni saqlash'}
            </button>
          </>
        )}
      </div>

      <p className="muted" style={{ fontSize: 13, margin: '6px 0 10px' }}>
        {mode === 'road' ? (
          drawing ? (
            <>
              ✏️ Chizish yoniq — xaritani bosib yo‘l nuqtalarini ketma-ket qo‘shing.
              Nuqtalar: <strong>{draft.length}</strong>
            </>
          ) : (
            <>“Chizishni boshlash”ni bosing, so‘ng xarita bo‘ylab nuqtalar qo‘ying.</>
          )
        ) : placeDraft ? (
          <>📍 Joy nuqtasi belgilandi — nom va turini tanlab “Joyni saqlash”ni bosing.</>
        ) : (
          <>
            Xaritani kerakli manzilga bosing — oshxona, parkovka, shifoxona kabi
            joyni belgilang. (Bosgan joyingizda nuqta paydo bo‘ladi.)
          </>
        )}
      </p>

      <RoadMap
        roads={roads}
        areas={areas}
        draft={draft}
        draftKind={roadKind}
        clickEnabled={clickEnabled}
        selectedRoadId={selectedRoadId}
        selectedPlaceId={selectedPlaceId}
        placeDraft={placeDraft}
        onMapClick={onMapClick}
        onSelectRoad={setSelectedRoadId}
        onSelectPlace={setSelectedPlaceId}
      />

      {/* Rang izohi */}
      <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', marginTop: 12 }}>
        {ROAD_KINDS.map((k) => (
          <span key={k} className="muted" style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
            <span
              style={{
                width: 18,
                height: 4,
                borderRadius: 2,
                background: ROAD_COLORS[k],
                display: 'inline-block',
              }}
            />
            {ROAD_KIND_LABELS[k]} ({grouped[k].length})
          </span>
        ))}
      </div>

      {/* Yo'llar ro'yxati (o'chirish) */}
      {roads.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 12 }}>
          {roads.map((r) => (
            <span
              key={r.id}
              className="badge"
              style={{
                background: ROAD_COLORS[r.kind] ?? ROAD_COLORS.street,
                cursor: 'pointer',
                opacity: selectedRoadId === r.id ? 1 : 0.85,
                outline: selectedRoadId === r.id ? '2px solid #1a202c' : 'none',
              }}
              title="Tanlash uchun bosing · ✕ bilan o'chiring"
              onClick={() => setSelectedRoadId(r.id)}
            >
              {r.name}{' '}
              <span
                onClick={(e) => {
                  e.stopPropagation();
                  removeRoad(r);
                }}
                style={{ marginLeft: 4 }}
              >
                ✕
              </span>
            </span>
          ))}
        </div>
      )}

      {/* Joylar ro'yxati (turi bo'yicha rangli, ✕ bilan o'chirish) */}
      {allPlaces.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 10 }}>
          {allPlaces.map((p) => {
            const cat = placeCategory(p.category);
            return (
              <span
                key={p.id}
                className="badge"
                style={{
                  background: cat.color,
                  cursor: 'pointer',
                  outline: selectedPlaceId === p.id ? '2px solid #1a202c' : 'none',
                }}
                title="Tanlash · ✕ bilan o'chirish"
                onClick={() => setSelectedPlaceId(p.id)}
              >
                {cat.emoji} {p.label}{' '}
                <span
                  onClick={(e) => {
                    e.stopPropagation();
                    removePlace(p.id);
                  }}
                  style={{ marginLeft: 4 }}
                >
                  ✕
                </span>
              </span>
            );
          })}
        </div>
      )}
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
