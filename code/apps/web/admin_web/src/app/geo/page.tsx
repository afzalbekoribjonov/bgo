'use client';

import dynamic from 'next/dynamic';
import { useCallback, useEffect, useState } from 'react';
import {
  addGeoPlace,
  createGeoArea,
  deleteGeoArea,
  deleteGeoPlace,
  getGeoAreas,
  importOsmPlaces,
  importOsmRoads,
} from '@/lib/api';
import { useToast } from '@/components/toast';
import { useDialog } from '@/components/dialog';
import { PLACE_CATEGORIES, placeCategory } from '@/lib/place-style';
import type { GeoPlace, ServiceArea } from '@/lib/types';

type Tab = 'areas' | 'roads' | 'import';

const GeoMap = dynamic(() => import('@/components/geo-map'), {
  ssr: false,
  loading: () => (
    <div
      style={{
        height: 420,
        background: 'var(--surface-2)',
        border: '1px solid var(--border)',
        borderRadius: 10,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 10,
        color: 'var(--text-muted)',
      }}
    >
      <div className="spinner" />
      <span style={{ fontSize: 13 }}>Xarita yuklanmoqda…</span>
    </div>
  ),
});

export default function GeoPage() {
  const toast = useToast();
  const dialog = useDialog();
  const [tab, setTab] = useState<Tab>('areas');
  const [areas, setAreas] = useState<ServiceArea[]>([]);
  const [loading, setLoading] = useState(true);
  const [importingRoads, setImportingRoads] = useState(false);
  const [importingPlaces, setImportingPlaces] = useState(false);

  // Expand state
  const [openArea, setOpenArea] = useState<string | null>(null);

  // Create area form
  const [showAreaForm, setShowAreaForm] = useState(false);
  const [areaName, setAreaName] = useState('');
  const [areaBusy, setAreaBusy] = useState(false);

  // Add place form
  const [placeLabel, setPlaceLabel] = useState('');
  const [placeLat, setPlaceLat] = useState('');
  const [placeLng, setPlaceLng] = useState('');
  const [placeAreaId, setPlaceAreaId] = useState('');
  const [placeCat, setPlaceCat] = useState('');
  const [placeBusy, setPlaceBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setAreas(await getGeoAreas());
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => { load(); }, [load]);

  async function addArea() {
    if (!areaName.trim()) { toast('Hudud nomini kiriting', 'error'); return; }
    setAreaBusy(true);
    try {
      await createGeoArea({
        name: areaName.trim(),
        centerLat: 40.5,
        centerLng: 69.5,
        boundary: [],
        isActive: true,
      });
      setAreaName(''); setShowAreaForm(false);
      toast("Hudud qo'shildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setAreaBusy(false);
    }
  }

  async function removeArea(a: ServiceArea) {
    const ok = await dialog.confirm(
      `"${a.name}" hududini va uning barcha joylarini o'chirasizmi?`,
      { title: "Hududni o'chirish", danger: true },
    );
    if (!ok) return;
    try {
      await deleteGeoArea(a.id);
      toast("O'chirildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  async function addPlace() {
    if (!placeLabel.trim() || !placeLat || !placeLng || !placeAreaId) {
      toast("Barcha maydonlarni to'ldiring", 'error');
      return;
    }
    setPlaceBusy(true);
    try {
      await addGeoPlace(placeAreaId, {
        label: placeLabel.trim(),
        lat: parseFloat(placeLat),
        lng: parseFloat(placeLng),
        ...(placeCat ? { category: placeCat } : {}),
      });
      setPlaceLabel(''); setPlaceLat(''); setPlaceLng(''); setPlaceCat('');
      toast("Joy qo'shildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setPlaceBusy(false);
    }
  }

  async function removePlace(p: GeoPlace) {
    const ok = await dialog.confirm(
      `"${p.label}" joyini o'chirasizmi?`,
      { title: "Joyni o'chirish", danger: true },
    );
    if (!ok) return;
    try {
      await deleteGeoPlace(p.id);
      toast("O'chirildi", 'success');
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    }
  }

  async function doImportRoads() {
    const ok = await dialog.confirm(
      "OSM dan yo'llar import qilinadi. Bu biroz vaqt oladi.",
      { title: "OSM yo'llarni import qilish" },
    );
    if (!ok) return;
    setImportingRoads(true);
    try {
      const r = await importOsmRoads();
      await dialog.alert(
        `${r.imported} ta yo'l import qilindi.`,
        { title: 'Import yakunlandi' },
      );
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setImportingRoads(false);
    }
  }

  async function doImportPlaces() {
    const ok = await dialog.confirm(
      'OSM dan joylar (POI) import qilinadi. Bu biroz vaqt oladi.',
      { title: 'OSM joylarni import qilish' },
    );
    if (!ok) return;
    setImportingPlaces(true);
    try {
      const r = await importOsmPlaces();
      await dialog.alert(
        `${r.imported} ta joy import qilindi, ${r.skipped} ta o'tkazib yuborildi.`,
        { title: 'Import yakunlandi' },
      );
      await load();
    } catch (e) {
      toast((e as Error).message, 'error');
    } finally {
      setImportingPlaces(false);
    }
  }

  const totalPlaces = areas.reduce((s, a) => s + a.places.length, 0);

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Hududlar va joylar</h1>
          <p className="page-subtitle">
            {areas.length} ta hudud · {totalPlaces} ta joy
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div className="section-tabs" style={{ marginBottom: 20 }}>
        <button className={`section-tab ${tab === 'areas' ? 'active' : ''}`} onClick={() => setTab('areas')}>
          <span>🗺️</span> Hududlar
        </button>
        <button className={`section-tab ${tab === 'roads' ? 'active' : ''}`} onClick={() => setTab('roads')}>
          <span>🛣️</span> Xarita muharriri
        </button>
        <button className={`section-tab ${tab === 'import' ? 'active' : ''}`} onClick={() => setTab('import')}>
          <span>📥</span> OSM import
        </button>
      </div>

      {/* ===== AREAS TAB ===== */}
      {tab === 'areas' && (
        <>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 16 }}>
            <button className="btn" onClick={() => setShowAreaForm((v) => !v)}>
              {showAreaForm ? '✕ Yopish' : '+ Yangi hudud'}
            </button>
          </div>

          {showAreaForm && (
            <div className="card" style={{ marginBottom: 16 }}>
              <div className="card-header">
                <span className="card-title">Yangi xizmat hududi qo'shish</span>
              </div>
              <div className="card-body">
                <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                  <div style={{ flex: 1 }}>
                    <label>Hudud nomi *</label>
                    <input
                      value={areaName}
                      onChange={(e) => setAreaName(e.target.value)}
                      placeholder="Beshariq markazi"
                    />
                  </div>
                  <div style={{ paddingTop: 16 }}>
                    <button className="btn" disabled={areaBusy} onClick={addArea}>
                      {areaBusy ? "Qo'shilyapti..." : "Qo'shish"}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {loading ? (
            <div>
              {[...Array(3)].map((_, i) => (
                <div key={i} className="card" style={{ marginBottom: 8, padding: '16px 20px' }}>
                  <div className="sk sk-line" style={{ width: '30%', marginBottom: 8, height: 15 }} />
                  <div className="sk sk-line sk-line-md" style={{ height: 12 }} />
                </div>
              ))}
            </div>
          ) : areas.length === 0 ? (
            <div className="card">
              <div className="empty">
                <div className="empty-icon">🗺️</div>
                <div className="empty-title">Hudud yo'q</div>
                <div className="empty-desc">Yangi xizmat hududi yarating</div>
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {areas.map((a) => (
                <div key={a.id} className="card">
                  {/* Area header */}
                  <div
                    className="card-header"
                    style={{ cursor: 'pointer' }}
                    onClick={() => setOpenArea(openArea === a.id ? null : a.id)}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <span style={{ fontSize: 18 }}>🗺️</span>
                      <div>
                        <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--text)' }}>{a.name}</div>
                        <div style={{ fontSize: 12.5, color: 'var(--text-muted)', marginTop: 2 }}>
                          {a.places.length} ta joy belgilangan
                        </div>
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                      <span
                        className="badge"
                        style={{ background: a.isActive ? 'var(--green)' : '#64748b', fontSize: 11.5 }}
                      >
                        {a.isActive ? 'Faol' : 'Nofaol'}
                      </span>
                      <button
                        className="btn btn-sm red"
                        onClick={(e) => { e.stopPropagation(); removeArea(a); }}
                      >
                        🗑
                      </button>
                      <span style={{ color: 'var(--text-muted)', transform: openArea === a.id ? 'rotate(90deg)' : 'none', transition: 'transform 150ms' }}>›</span>
                    </div>
                  </div>

                  {/* Expanded: places */}
                  {openArea === a.id && (
                    <div className="card-body" style={{ borderTop: '1px solid var(--border)' }}>
                      {/* Add place form */}
                      <div
                        style={{
                          padding: '14px',
                          background: 'var(--surface-2)',
                          borderRadius: 10,
                          border: '1px solid var(--border)',
                          marginBottom: 14,
                        }}
                      >
                        <div style={{ fontWeight: 600, fontSize: 13, color: 'var(--text-2)', marginBottom: 10 }}>
                          + Joy qo'shish
                        </div>
                        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                          <div style={{ flex: 2, minWidth: 120 }}>
                            <label>Nom</label>
                            <input
                              value={placeAreaId === a.id ? placeLabel : ''}
                              placeholder="Bozor, mahalla..."
                              onChange={(e) => { setPlaceLabel(e.target.value); setPlaceAreaId(a.id); }}
                            />
                          </div>
                          <div style={{ flex: 1, minWidth: 130 }}>
                            <label>Kategoriya</label>
                            <select
                              value={placeAreaId === a.id ? placeCat : ''}
                              onChange={(e) => { setPlaceCat(e.target.value); setPlaceAreaId(a.id); }}
                            >
                              <option value="">— tanlang —</option>
                              {PLACE_CATEGORIES.map((c) => (
                                <option key={c.key} value={c.key}>
                                  {c.emoji} {c.label}
                                </option>
                              ))}
                            </select>
                          </div>
                          <div style={{ flex: 1, minWidth: 90 }}>
                            <label>Kenglik (lat)</label>
                            <input
                              value={placeAreaId === a.id ? placeLat : ''}
                              inputMode="decimal"
                              placeholder="40.5xxx"
                              onChange={(e) => { setPlaceLat(e.target.value); setPlaceAreaId(a.id); }}
                            />
                          </div>
                          <div style={{ flex: 1, minWidth: 90 }}>
                            <label>Uzunlik (lng)</label>
                            <input
                              value={placeAreaId === a.id ? placeLng : ''}
                              inputMode="decimal"
                              placeholder="69.5xxx"
                              onChange={(e) => { setPlaceLng(e.target.value); setPlaceAreaId(a.id); }}
                            />
                          </div>
                          <div style={{ paddingTop: 16 }}>
                            <button
                              className="btn btn-sm"
                              disabled={placeBusy || placeAreaId !== a.id}
                              onClick={addPlace}
                            >
                              {placeBusy && placeAreaId === a.id ? '...' : "Qo'sh"}
                            </button>
                          </div>
                        </div>
                      </div>

                      {/* Places list */}
                      {a.places.length === 0 ? (
                        <div style={{ textAlign: 'center', padding: '24px 0', color: 'var(--text-muted)', fontSize: 13 }}>
                          Joy belgilanmagan
                        </div>
                      ) : (
                        <div
                          style={{
                            display: 'grid',
                            gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
                            gap: 8,
                          }}
                        >
                          {a.places.map((p) => (
                            <div
                              key={p.id}
                              style={{
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'space-between',
                                gap: 8,
                                padding: '8px 12px',
                                background: 'var(--surface)',
                                border: '1px solid var(--border)',
                                borderRadius: 8,
                              }}
                            >
                              <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
                                <span
                                  style={{
                                    width: 28, height: 28, borderRadius: '50%', flexShrink: 0,
                                    background: placeCategory(p.category).color,
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    fontSize: 14,
                                  }}
                                >
                                  {placeCategory(p.category).emoji}
                                </span>
                                <div style={{ minWidth: 0 }}>
                                  <div style={{ fontWeight: 600, fontSize: 13, color: 'var(--text-2)' }}>{p.label}</div>
                                  <div style={{ fontSize: 11.5, color: 'var(--text-muted)', fontFamily: 'monospace' }}>
                                    {p.lat.toFixed(4)}, {p.lng.toFixed(4)}
                                  </div>
                                </div>
                              </div>
                              <button
                                className="btn btn-sm red"
                                style={{ padding: '3px 8px', flexShrink: 0 }}
                                onClick={() => removePlace(p)}
                              >
                                ✕
                              </button>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </>
      )}

      {/* ===== MAP EDITOR TAB ===== */}
      {tab === 'roads' && (
        <div>
          <div className="info-block blue" style={{ marginBottom: 16, fontSize: 13 }}>
            Xaritada yo'llarni ko'rish va tahrirlash uchun GeoMap muharririga o'ting. OSM import
            qilingan yo'llar va qo'lda chizilgan yo'llar bu yerda ko'rinadi.
          </div>
          <div className="card">
            <div className="card-body" style={{ padding: 0, overflow: 'hidden', borderRadius: 12 }}>
              <GeoMap areas={areas} onRefresh={load} />
            </div>
          </div>
        </div>
      )}

      {/* ===== OSM IMPORT TAB ===== */}
      {tab === 'import' && (
        <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', alignItems: 'flex-start' }}>
          {/* Roads */}
          <div className="card" style={{ flex: 1, minWidth: 260 }}>
            <div className="card-header">
              <span className="card-title">🛣️ Yo'llarni import qilish</span>
            </div>
            <div className="card-body">
              <div className="info-block amber" style={{ marginBottom: 14, fontSize: 13 }}>
                Bu amal OSM'dan Beshariq yo'llarini yuklab, mavjud yo'llar ustiga yozadi.
                Qo'lda chizilgan yo'llar o'chishi mumkin!
              </div>
              <p style={{ fontSize: 13, color: 'var(--text-3)', marginBottom: 16, lineHeight: 1.6 }}>
                OpenStreetMap'dan Beshariq tumani yo'llarini import qiling. Bu yo'llar customer
                va driver xaritalarida ko'rinadi va OSRM navigatsiya uchun ishlatiladi.
              </p>
              <button className="btn amber" disabled={importingRoads} onClick={doImportRoads}>
                {importingRoads ? (
                  <>
                    <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2, borderColor: 'rgba(255,255,255,0.3)', borderTopColor: '#fff' }} />
                    Import qilinmoqda...
                  </>
                ) : (
                  '📥 Yo\'llarni import qilish'
                )}
              </button>
            </div>
          </div>

          {/* Places */}
          <div className="card" style={{ flex: 1, minWidth: 260 }}>
            <div className="card-header">
              <span className="card-title">📍 Joylarni import qilish</span>
            </div>
            <div className="card-body">
              <div className="info-block blue" style={{ marginBottom: 14, fontSize: 13 }}>
                Bu amal takroriy joylarni o'tkazib yuboradi. Bir necha marta ishlatsangiz ham xavfsiz.
              </div>
              <p style={{ fontSize: 13, color: 'var(--text-3)', marginBottom: 16, lineHeight: 1.6 }}>
                OSM'dan qishloqlar, mahallalar, bozorlar va boshqa muhim joylarni import qiling.
                Bu joylar mijozga manzil tanlashda taklif etiladi.
              </p>
              <button className="btn" disabled={importingPlaces} onClick={doImportPlaces}>
                {importingPlaces ? (
                  <>
                    <span className="spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
                    Import qilinmoqda...
                  </>
                ) : (
                  '📥 Joylarni import qilish'
                )}
              </button>
            </div>
          </div>

          {/* Stats */}
          <div className="card" style={{ flex: 1, minWidth: 220 }}>
            <div className="card-header">
              <span className="card-title">📊 Joriy holat</span>
            </div>
            <div className="card-body">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 13, color: 'var(--text-3)' }}>Hududlar</span>
                  <span style={{ fontWeight: 700, color: 'var(--text)' }}>{areas.length}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 13, color: 'var(--text-3)' }}>Joylar</span>
                  <span style={{ fontWeight: 700, color: 'var(--text)' }}>{totalPlaces}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 13, color: 'var(--text-3)' }}>Faol hududlar</span>
                  <span style={{ fontWeight: 700, color: 'var(--green)' }}>
                    {areas.filter((a) => a.isActive).length}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
