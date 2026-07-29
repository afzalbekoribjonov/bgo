'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  addGeoMarker,
  addGeoPlace,
  addGeoRoad,
  deleteGeoMarker,
  deleteGeoPlace,
  deleteGeoRoad,
  getGeoMarkers,
  getGeoRoads,
  updateGeoRoad,
} from '@/lib/api';
import { PLACE_CATEGORIES, placeCategory } from '@/lib/place-style';
import type {
  GeoPlace,
  MapMarker,
  MapRoad,
  MarkerKind,
  RoadKind,
  ServiceArea,
  UpdateRoadInput,
} from '@/lib/types';
import RoadMap from '@/components/road-map';

type LatLng = [number, number];
type EditMode = 'view' | 'road' | 'marker' | 'place';

const ROAD_KINDS: { key: RoadKind; label: string; color: string }[] = [
  { key: 'center', label: 'Markaziy', color: '#e8960c' },
  { key: 'main', label: 'Asosiy', color: '#f7bd3e' },
  { key: 'street', label: "Ko'cha", color: '#94a3b8' },
  { key: 'farmland', label: '🌾 Dala', color: '#66bb6a' },
];

const MARKER_KINDS: { key: MarkerKind; emoji: string; label: string }[] = [
  { key: 'shop', emoji: '🏪', label: "Do'kon" },
  { key: 'sticker', emoji: '📌', label: 'Stiker' },
  { key: 'construction', emoji: '🚧', label: "Ta'mirlash" },
  { key: 'traffic_light', emoji: '🚦', label: 'Svetafor' },
  { key: 'restriction', emoji: '⛔', label: "Taqiqlangan" },
  { key: 'farm', emoji: '🚜', label: 'Fermer' },
];

interface GeoMapProps {
  areas: ServiceArea[];
  onRefresh: () => void;
}

export default function GeoMap({ areas, onRefresh }: GeoMapProps) {
  const [roads, setRoads] = useState<MapRoad[]>([]);
  const [markers, setMarkers] = useState<MapMarker[]>([]);
  const [loading, setLoading] = useState(true);

  // Road drawing
  const [draft, setDraft] = useState<LatLng[]>([]);
  const [draftKind, setDraftKind] = useState<RoadKind>('street');
  const [draftName, setDraftName] = useState('');
  const [draftAttrs, setDraftAttrs] = useState({
    isOneWay: false,
    isUnderConstruction: false,
    hasTrafficLight: false,
    isRestricted: false,
    speedLimit: '',
  });

  // Mode
  const [mode, setMode] = useState<EditMode>('view');

  // Selection
  const [selectedRoadId, setSelectedRoadId] = useState<string | null>(null);
  const [selectedMarkerId, setSelectedMarkerId] = useState<string | null>(null);
  const [selectedPlaceId, setSelectedPlaceId] = useState<string | null>(null);

  // Road attribute editing
  const [editAttrs, setEditAttrs] = useState<UpdateRoadInput>({});
  const [editAttrsDirty, setEditAttrsDirty] = useState(false);
  const [savingAttrs, setSavingAttrs] = useState(false);

  // Marker placement
  const [markerKind, setMarkerKind] = useState<MarkerKind>('shop');
  const [markerLabel, setMarkerLabel] = useState('');
  const [pendingMarker, setPendingMarker] = useState<LatLng | null>(null);
  const [savingMarker, setSavingMarker] = useState(false);

  // Place placement
  const [placeDraft, setPlaceDraft] = useState<LatLng | null>(null);
  const [placeLabelDraft, setPlaceLabelDraft] = useState('');
  const [placeCategoryDraft, setPlaceCategoryDraft] = useState('landmark');
  const [savingPlace, setSavingPlace] = useState(false);

  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState<{ text: string; ok: boolean } | null>(null);

  const loadData = useCallback(async () => {
    try {
      const [r, m] = await Promise.all([getGeoRoads(), getGeoMarkers()]);
      setRoads(r);
      setMarkers(m);
    } catch {
      /* ignore */
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadData(); }, [loadData]);

  // Sync editAttrs when selected road changes
  useEffect(() => {
    if (selectedRoadId) {
      const r = roads.find((x) => x.id === selectedRoadId);
      if (r) {
        setEditAttrs({
          name: r.name,
          kind: r.kind,
          isOneWay: r.isOneWay,
          isUnderConstruction: r.isUnderConstruction,
          hasTrafficLight: r.hasTrafficLight,
          isRestricted: r.isRestricted,
          speedLimit: r.speedLimit,
        });
        setEditAttrsDirty(false);
      }
    }
  }, [selectedRoadId, roads]);

  function showMsg(text: string, ok = true) {
    setMsg({ text, ok });
    setTimeout(() => setMsg(null), 3000);
  }

  function handleMapClick(lat: number, lng: number) {
    if (mode === 'road') {
      setDraft((d) => [...d, [lat, lng]]);
    } else if (mode === 'marker') {
      setPendingMarker([lat, lng]);
    } else if (mode === 'place') {
      setPlaceDraft([lat, lng]);
    }
  }

  function undoPoint() { setDraft((d) => d.slice(0, -1)); }

  function cancelDraft() {
    setDraft([]);
    setDraftName('');
    setDraftAttrs({ isOneWay: false, isUnderConstruction: false, hasTrafficLight: false, isRestricted: false, speedLimit: '' });
    setMode('view');
  }

  function cancelMarker() {
    setPendingMarker(null);
    setMarkerLabel('');
    setMode('view');
  }

  function cancelPlace() {
    setPlaceDraft(null);
    setPlaceLabelDraft('');
    setPlaceCategoryDraft('landmark');
    setMode('view');
  }

  async function saveRoad() {
    if (draft.length < 2) { showMsg("Kamida 2 ta nuqta kerak", false); return; }
    if (!draftName.trim()) { showMsg("Yo'l nomini kiriting", false); return; }
    if (!areas[0]) { showMsg('Avval hudud yarating', false); return; }
    setSaving(true);
    try {
      await addGeoRoad(areas[0].id, {
        name: draftName.trim(),
        kind: draftKind,
        points: draft,
        isOneWay: draftAttrs.isOneWay,
        isUnderConstruction: draftAttrs.isUnderConstruction,
        hasTrafficLight: draftAttrs.hasTrafficLight,
        isRestricted: draftAttrs.isRestricted,
        speedLimit: draftAttrs.speedLimit ? parseInt(draftAttrs.speedLimit, 10) : undefined,
      });
      showMsg(`"${draftName}" saqlandi ✓`);
      cancelDraft();
      await loadData();
    } catch (e) {
      showMsg((e as Error).message, false);
    } finally {
      setSaving(false);
    }
  }

  async function saveMarker() {
    if (!pendingMarker) return;
    if (!areas[0]) { showMsg('Avval hudud yarating', false); return; }
    setSavingMarker(true);
    try {
      await addGeoMarker(areas[0].id, {
        lat: pendingMarker[0],
        lng: pendingMarker[1],
        kind: markerKind,
        label: markerLabel.trim() || undefined,
      });
      showMsg('Belgi saqlandi ✓');
      cancelMarker();
      await loadData();
    } catch (e) {
      showMsg((e as Error).message, false);
    } finally {
      setSavingMarker(false);
    }
  }

  async function savePlace() {
    if (!placeDraft) { showMsg("Xaritadagi joyni bosing", false); return; }
    if (!placeLabelDraft.trim()) { showMsg('Joy nomini kiriting', false); return; }
    if (!areas[0]) { showMsg('Avval hudud yarating', false); return; }
    setSavingPlace(true);
    try {
      await addGeoPlace(areas[0].id, {
        label: placeLabelDraft.trim(),
        lat: placeDraft[0],
        lng: placeDraft[1],
        category: placeCategoryDraft,
      });
      showMsg(`"${placeLabelDraft}" saqlandi ✓`);
      cancelPlace();
      onRefresh();
    } catch (e) {
      showMsg((e as Error).message, false);
    } finally {
      setSavingPlace(false);
    }
  }

  async function deleteSelectedRoad() {
    if (!selectedRoadId) return;
    try {
      await deleteGeoRoad(selectedRoadId);
      setSelectedRoadId(null);
      showMsg("O'chirildi");
      await loadData();
    } catch (e) {
      showMsg((e as Error).message, false);
    }
  }

  async function deleteSelectedMarker() {
    if (!selectedMarkerId) return;
    try {
      await deleteGeoMarker(selectedMarkerId);
      setSelectedMarkerId(null);
      showMsg("Belgi o'chirildi");
      await loadData();
    } catch (e) {
      showMsg((e as Error).message, false);
    }
  }

  async function deleteSelectedPlace() {
    if (!selectedPlaceId) return;
    try {
      await deleteGeoPlace(selectedPlaceId);
      setSelectedPlaceId(null);
      showMsg("Joy o'chirildi");
      onRefresh();
    } catch (e) {
      showMsg((e as Error).message, false);
    }
  }

  async function saveRoadAttrs() {
    if (!selectedRoadId) return;
    setSavingAttrs(true);
    try {
      const patch: UpdateRoadInput = {
        ...editAttrs,
        speedLimit: editAttrs.speedLimit != null ? editAttrs.speedLimit : null,
      };
      await updateGeoRoad(selectedRoadId, patch);
      showMsg("Yo'l atributlari saqlandi ✓");
      setEditAttrsDirty(false);
      await loadData();
    } catch (e) {
      showMsg((e as Error).message, false);
    } finally {
      setSavingAttrs(false);
    }
  }

  if (loading) {
    return (
      <div style={{ height: 480, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 10 }}>
        <div className="spinner" />
        <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>Xarita ma'lumotlari yuklanmoqda…</span>
      </div>
    );
  }

  const selectedRoad = selectedRoadId ? roads.find((r) => r.id === selectedRoadId) : null;
  const selectedMarker = selectedMarkerId ? markers.find((m) => m.id === selectedMarkerId) : null;
  const places: GeoPlace[] = areas.flatMap((a) => a.places);
  const selectedPlace = selectedPlaceId ? places.find((p) => p.id === selectedPlaceId) : null;

  const clickEnabled = mode === 'road' || mode === 'marker' || mode === 'place';

  return (
    <div>
      {/* Toolbar */}
      <div style={{
        display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap',
        padding: '12px 16px', borderBottom: '1px solid var(--border)', background: 'var(--surface-2)',
      }}>
        {mode === 'view' ? (
          <>
            <button className="btn btn-sm" onClick={() => { setMode('road'); setSelectedRoadId(null); setSelectedMarkerId(null); setSelectedPlaceId(null); }}>
              ✏️ Yo'l chizish
            </button>
            <button className="btn btn-sm" style={{ background: 'var(--amber)', color: '#fff', border: 'none' }}
              onClick={() => { setMode('marker'); setSelectedRoadId(null); setSelectedMarkerId(null); setSelectedPlaceId(null); }}>
              📌 Belgi qo'yish
            </button>
            <button className="btn btn-sm" style={{ background: '#2f9e44', color: '#fff', border: 'none' }}
              onClick={() => { setMode('place'); setSelectedRoadId(null); setSelectedMarkerId(null); setSelectedPlaceId(null); }}>
              🏘️ Joy qo'shish
            </button>
            {selectedRoadId && (
              <button className="btn btn-sm red" onClick={deleteSelectedRoad}>🗑 Yo'l o'chirish</button>
            )}
            {selectedMarkerId && (
              <button className="btn btn-sm red" onClick={deleteSelectedMarker}>🗑 Belgi o'chirish</button>
            )}
            {selectedPlaceId && (
              <button className="btn btn-sm red" onClick={deleteSelectedPlace}>🗑 Joy o'chirish</button>
            )}
            <span style={{ fontSize: 12.5, color: 'var(--text-muted)', marginLeft: 'auto' }}>
              {roads.length} yo'l · {markers.length} belgi · {places.length} joy
            </span>
          </>
        ) : mode === 'road' ? (
          <>
            {ROAD_KINDS.map((k) => (
              <button key={k.key} className={`chip ${draftKind === k.key ? 'active' : ''}`}
                style={{ fontSize: 12 }} onClick={() => setDraftKind(k.key)}>
                <span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: '50%', background: k.color, marginRight: 4 }} />
                {k.label}
              </button>
            ))}
            <input value={draftName} onChange={(e) => setDraftName(e.target.value)}
              placeholder="Yo'l nomi" style={{ width: 140, height: 34, fontSize: 13 }} />
            <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, cursor: 'pointer', color: draftAttrs.isOneWay ? 'var(--primary)' : 'var(--text-muted)' }}>
              <input type="checkbox" checked={draftAttrs.isOneWay}
                onChange={(e) => setDraftAttrs((p) => ({ ...p, isOneWay: e.target.checked }))} />
              ↗ Bir tomonlama
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, cursor: 'pointer', color: draftAttrs.isUnderConstruction ? 'var(--amber)' : 'var(--text-muted)' }}>
              <input type="checkbox" checked={draftAttrs.isUnderConstruction}
                onChange={(e) => setDraftAttrs((p) => ({ ...p, isUnderConstruction: e.target.checked }))} />
              🚧 Ta'mirlash
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, cursor: 'pointer', color: draftAttrs.hasTrafficLight ? 'var(--green)' : 'var(--text-muted)' }}>
              <input type="checkbox" checked={draftAttrs.hasTrafficLight}
                onChange={(e) => setDraftAttrs((p) => ({ ...p, hasTrafficLight: e.target.checked }))} />
              🚦 Svetafor
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, cursor: 'pointer', color: draftAttrs.isRestricted ? 'var(--red)' : 'var(--text-muted)' }}>
              <input type="checkbox" checked={draftAttrs.isRestricted}
                onChange={(e) => setDraftAttrs((p) => ({ ...p, isRestricted: e.target.checked }))} />
              ⛔ Taqiqlangan
            </label>
            <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{draft.length} nuqta</span>
            <button className="btn btn-sm ghost" onClick={undoPoint} disabled={!draft.length}>↩ Oxirgi</button>
            <button className="btn btn-sm" disabled={saving} onClick={saveRoad}>{saving ? '...' : '💾 Saqlash'}</button>
            <button className="btn btn-sm red" onClick={cancelDraft}>✕ Bekor</button>
          </>
        ) : mode === 'marker' ? (
          <>
            {MARKER_KINDS.map((k) => (
              <button key={k.key}
                className={`chip ${markerKind === k.key ? 'active' : ''}`}
                style={{ fontSize: 12 }}
                onClick={() => setMarkerKind(k.key)}>
                {k.emoji} {k.label}
              </button>
            ))}
            <input value={markerLabel} onChange={(e) => setMarkerLabel(e.target.value)}
              placeholder="Nom (ixtiyoriy)" style={{ width: 140, height: 34, fontSize: 13 }} />
            {pendingMarker ? (
              <>
                <span style={{ fontSize: 12, color: 'var(--primary)' }}>
                  📍 {pendingMarker[0].toFixed(4)}, {pendingMarker[1].toFixed(4)}
                </span>
                <button className="btn btn-sm" disabled={savingMarker} onClick={saveMarker}>
                  {savingMarker ? '...' : '💾 Saqlash'}
                </button>
                <button className="btn btn-sm ghost" onClick={() => setPendingMarker(null)}>↩ Qayta</button>
              </>
            ) : (
              <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>Xaritaga bosing</span>
            )}
            <button className="btn btn-sm red" onClick={cancelMarker}>✕ Bekor</button>
          </>
        ) : mode === 'place' ? (
          <>
            {/* Kategoriya tanlash */}
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', flex: 1 }}>
              {PLACE_CATEGORIES.map((cat) => (
                <button
                  key={cat.key}
                  className={`chip ${placeCategoryDraft === cat.key ? 'active' : ''}`}
                  style={{ fontSize: 11.5 }}
                  onClick={() => setPlaceCategoryDraft(cat.key)}
                >
                  {cat.emoji} {cat.label}
                </button>
              ))}
            </div>
            <input
              value={placeLabelDraft}
              onChange={(e) => setPlaceLabelDraft(e.target.value)}
              placeholder="Joy nomi (majburiy)"
              style={{ width: 160, height: 34, fontSize: 13, flexShrink: 0 }}
            />
            {placeDraft ? (
              <>
                <span style={{ fontSize: 12, color: '#2f9e44', flexShrink: 0 }}>
                  📍 {placeDraft[0].toFixed(4)}, {placeDraft[1].toFixed(4)}
                </span>
                <button className="btn btn-sm" disabled={savingPlace} onClick={savePlace} style={{ flexShrink: 0 }}>
                  {savingPlace ? '...' : '💾 Saqlash'}
                </button>
                <button className="btn btn-sm ghost" onClick={() => setPlaceDraft(null)} style={{ flexShrink: 0 }}>↩ Qayta</button>
              </>
            ) : (
              <span style={{ fontSize: 12, color: 'var(--text-muted)', flexShrink: 0 }}>Xaritaga bosing</span>
            )}
            <button className="btn btn-sm red" onClick={cancelPlace} style={{ flexShrink: 0 }}>✕ Bekor</button>
          </>
        ) : null}
      </div>

      {/* Message */}
      {msg && (
        <div style={{
          padding: '8px 16px', fontSize: 13,
          background: msg.ok ? 'var(--green-light)' : 'var(--red-light)',
          color: msg.ok ? 'var(--green)' : 'var(--red)',
          borderBottom: '1px solid var(--border)', fontWeight: 600,
        }}>
          {msg.text}
        </div>
      )}

      {/* Hint strip */}
      {mode === 'road' && (
        <div style={{ padding: '8px 16px', fontSize: 12.5, color: 'var(--primary)', background: 'var(--primary-light)', borderBottom: '1px solid var(--primary-border)' }}>
          Xaritani bosib yo'l nuqtalarini qo'shing.{' '}
          {draft.length < 2 ? `Yana ${2 - draft.length} ta nuqta kerak.` : `${draft.length} ta nuqta — saqlashga tayyor.`}
        </div>
      )}
      {mode === 'marker' && !pendingMarker && (
        <div style={{ padding: '8px 16px', fontSize: 12.5, color: '#b45309', background: '#fef3c7', borderBottom: '1px solid #fde68a' }}>
          Belgi qo'yish uchun xaritadagi joyni bosing.
        </div>
      )}
      {mode === 'place' && !placeDraft && (
        <div style={{ padding: '8px 16px', fontSize: 12.5, color: '#276227', background: '#d3f9d8', borderBottom: '1px solid #b2f2bb' }}>
          Joy qo'shish: kategoriya va nom tanlang, keyin xaritadagi aniq joyni bosing.
        </div>
      )}

      {/* Map */}
      <RoadMap
        roads={roads}
        markers={markers}
        areas={areas}
        draft={draft}
        draftKind={draftKind}
        clickEnabled={clickEnabled}
        selectedRoadId={selectedRoadId}
        selectedMarkerId={selectedMarkerId}
        selectedPlaceId={selectedPlaceId}
        pendingMarker={pendingMarker}
        pendingMarkerKind={markerKind}
        placeDraft={mode === 'place' ? placeDraft : null}
        onMapClick={handleMapClick}
        onSelectRoad={(id) => {
          if (mode === 'view') {
            setSelectedRoadId(id === selectedRoadId ? null : id);
            setSelectedMarkerId(null);
            setSelectedPlaceId(null);
          }
        }}
        onSelectMarker={(id) => {
          if (mode === 'view') {
            setSelectedMarkerId(id === selectedMarkerId ? null : id);
            setSelectedRoadId(null);
            setSelectedPlaceId(null);
          }
        }}
        onSelectPlace={(id) => {
          if (mode === 'view') {
            setSelectedPlaceId(id === selectedPlaceId ? null : id);
            setSelectedRoadId(null);
            setSelectedMarkerId(null);
          }
        }}
      />

      {/* Selected road attribute panel */}
      {selectedRoad && mode === 'view' && (
        <div style={{ padding: '14px 16px', borderTop: '1px solid var(--border)', background: 'var(--surface-2)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12, flexWrap: 'wrap' }}>
            <span style={{ fontWeight: 700, fontSize: 14, color: 'var(--text)' }}>{selectedRoad.name}</span>
            <span style={{ fontSize: 12, color: 'var(--text-muted)', background: 'var(--surface)', border: '1px solid var(--border)', padding: '2px 8px', borderRadius: 5 }}>
              {selectedRoad.kind} · {selectedRoad.points.length} nuqta
            </span>
            <button className="btn btn-sm red" style={{ marginLeft: 'auto' }} onClick={deleteSelectedRoad}>
              🗑 O'chirish
            </button>
          </div>

          <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 12 }}>
            {([
              { field: 'isOneWay', label: '↗ Bir tomonlama', color: 'var(--primary)' },
              { field: 'isUnderConstruction', label: "🚧 Ta'mirlash", color: 'var(--amber)' },
              { field: 'hasTrafficLight', label: '🚦 Svetafor', color: 'var(--green)' },
              { field: 'isRestricted', label: '⛔ Taqiqlangan', color: 'var(--red)' },
            ] as { field: keyof UpdateRoadInput; label: string; color: string }[]).map(({ field, label, color }) => {
              const val = editAttrs[field] as boolean;
              return (
                <label key={field} style={{
                  display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, cursor: 'pointer',
                  padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border)',
                  background: val ? `${color}22` : 'var(--surface)',
                  color: val ? color : 'var(--text-muted)',
                  transition: 'all .15s',
                }}>
                  <input type="checkbox" checked={val ?? false}
                    onChange={(e) => {
                      setEditAttrs((p) => ({ ...p, [field]: e.target.checked }));
                      setEditAttrsDirty(true);
                    }} />
                  {label}
                </label>
              );
            })}
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <label style={{ fontSize: 13, color: 'var(--text-muted)' }}>Tezlik:</label>
              <input
                type="number" min={0} max={120}
                value={editAttrs.speedLimit ?? ''}
                placeholder="km/h"
                onChange={(e) => {
                  setEditAttrs((p) => ({ ...p, speedLimit: e.target.value ? parseInt(e.target.value, 10) : null }));
                  setEditAttrsDirty(true);
                }}
                style={{ width: 80, height: 32, fontSize: 13, padding: '0 8px' }}
              />
              <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>km/h</span>
            </div>
          </div>

          {editAttrsDirty && (
            <button className="btn btn-sm" disabled={savingAttrs} onClick={saveRoadAttrs}>
              {savingAttrs ? '...' : '💾 Saqlash'}
            </button>
          )}
        </div>
      )}

      {/* Selected marker info */}
      {selectedMarker && mode === 'view' && (() => {
        const mk = MARKER_KINDS.find((k) => k.key === selectedMarker.kind);
        return (
          <div style={{
            padding: '12px 16px', borderTop: '1px solid var(--border)',
            background: 'var(--surface-2)', display: 'flex', gap: 12, alignItems: 'center',
          }}>
            <span style={{ fontSize: 22 }}>{mk?.emoji ?? '📌'}</span>
            <div>
              <div style={{ fontWeight: 700, fontSize: 14 }}>{selectedMarker.label || mk?.label || selectedMarker.kind}</div>
              <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                {selectedMarker.lat.toFixed(4)}, {selectedMarker.lng.toFixed(4)}
              </div>
            </div>
            <button className="btn btn-sm red" style={{ marginLeft: 'auto' }} onClick={deleteSelectedMarker}>
              🗑 O'chirish
            </button>
          </div>
        );
      })()}

      {/* Selected place info */}
      {selectedPlace && mode === 'view' && (() => {
        const cat = placeCategory(selectedPlace.category);
        return (
          <div style={{
            padding: '12px 16px', borderTop: '1px solid var(--border)',
            background: 'var(--surface-2)', display: 'flex', gap: 12, alignItems: 'center',
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: '50%', flexShrink: 0,
              background: cat.color, display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 18,
            }}>
              {cat.emoji}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 700, fontSize: 14 }}>{selectedPlace.label}</div>
              <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                {cat.label} · {selectedPlace.lat.toFixed(4)}, {selectedPlace.lng.toFixed(4)}
              </div>
            </div>
            <button className="btn btn-sm red" style={{ flexShrink: 0 }} onClick={deleteSelectedPlace}>
              🗑 O'chirish
            </button>
          </div>
        );
      })()}
    </div>
  );
}
