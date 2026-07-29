'use client';

import { useState, useCallback, useMemo, useEffect } from 'react';
import Map, {
  Source,
  Layer,
  NavigationControl,
  Marker,
} from 'react-map-gl/maplibre';
import type { MapLayerMouseEvent, LngLatBoundsLike } from 'react-map-gl/maplibre';
import 'maplibre-gl/dist/maplibre-gl.css';

import { ROAD_COLORS } from '@/lib/road-style';
import { placeCategory } from '@/lib/place-style';
import type { MapMarker, MapRoad, MarkerKind, RoadKind, ServiceArea } from '@/lib/types';

type LatLng = [number, number];

const CENTER = { longitude: 70.6094, latitude: 40.4236 };
// Oldingi chegara (~18×18 km) tuman markazidan unча узoq bo'lmagan holda
// tugab, chekka qishloq/yo'llarni tahrirlashga imkon bermasdi. Endi butun
// tuman + qo'shni hududlar uchun keng zaxira bilan (~85×65 km).
const BOUNDS: LngLatBoundsLike = [[70.1094, 40.1236], [71.1094, 40.7236]];
/** OpenFreeMap Liberty — bepul, API key shart emas, binolar + yo'llar to'liq. */
const MAP_STYLE = 'https://tiles.openfreemap.org/styles/liberty';

const MARKER_EMOJI: Record<MarkerKind, string> = {
  shop: '🏪',
  sticker: '📌',
  construction: '🚧',
  traffic_light: '🚦',
  restriction: '⛔',
  farm: '🚜',
};

const ROAD_FILL_LAYERS = [
  'roads-fill-normal',
  'roads-fill-restricted',
  'roads-fill-construction',
  'farmland-fill',
];

export interface RoadMapProps {
  roads: MapRoad[];
  markers?: MapMarker[];
  areas: ServiceArea[];
  draft: LatLng[];
  draftKind: RoadKind;
  clickEnabled: boolean;
  selectedRoadId: string | null;
  selectedMarkerId?: string | null;
  selectedPlaceId: string | null;
  placeDraft: LatLng | null;
  pendingMarker?: LatLng | null;
  pendingMarkerKind?: MarkerKind;
  onMapClick: (lat: number, lng: number) => void;
  onSelectRoad: (id: string) => void;
  onSelectMarker?: (id: string) => void;
  onSelectPlace: (id: string) => void;
}

export default function RoadMap({
  roads,
  markers = [],
  areas,
  draft,
  draftKind,
  clickEnabled,
  selectedRoadId,
  selectedMarkerId = null,
  selectedPlaceId,
  placeDraft,
  pendingMarker = null,
  pendingMarkerKind = 'sticker',
  onMapClick,
  onSelectRoad,
  onSelectMarker,
  onSelectPlace,
}: RoadMapProps) {
  const [cursor, setCursor] = useState<string>('grab');
  const [mapZoom, setMapZoom] = useState(14);
  const places = useMemo(() => areas.flatMap((a) => a.places), [areas]);
  const draftColor = ROAD_COLORS[draftKind];

  // Zoom oshganda markerlar kichrayadi (katta zoomda joy egallashini oldini olish)
  const emojiSizeNormal = Math.max(14, Math.min(22, Math.round(36 - mapZoom)));
  const emojiSizeSelected = emojiSizeNormal + 8;

  useEffect(() => {
    if (!clickEnabled) setCursor('grab');
  }, [clickEnabled]);

  /* ── GeoJSON sources ── */

  const areasGeoJSON = useMemo(() => ({
    type: 'FeatureCollection' as const,
    features: areas.flatMap((a) =>
      a.boundary.map((ring, i) => ({
        type: 'Feature' as const,
        id: `${a.id}-${i}`,
        geometry: {
          type: 'Polygon' as const,
          // boundary store qilinishi: [lng, lat] — GeoJSON standart, MapLibre mos
          coordinates: [ring.map(([lng, lat]) => [lng, lat] as [number, number])],
        },
        properties: {},
      }))
    ),
  }), [areas]);

  const roadsGeoJSON = useMemo(() => ({
    type: 'FeatureCollection' as const,
    // farmland — chiziq emas, poligon qatlamida chiziladi (pastda).
    features: roads.filter((r) => r.kind !== 'farmland').map((r) => ({
      type: 'Feature' as const,
      id: r.id,
      geometry: {
        type: 'LineString' as const,
        // road.points: [lat, lng] → MapLibre: [lng, lat]
        coordinates: r.points.map(([lat, lng]) => [lng, lat] as [number, number]),
      },
      properties: {
        id: r.id,
        kind: r.kind,
        name: r.name,
        selected: r.id === selectedRoadId,
        isRestricted: r.isRestricted ?? false,
        isUnderConstruction: r.isUnderConstruction ?? false,
        isOneWay: r.isOneWay ?? false,
        hasTrafficLight: r.hasTrafficLight ?? false,
        speedLimit: r.speedLimit ?? null,
      },
    })),
  }), [roads, selectedRoadId]);

  /** Dehqonchilik maydonlari — nuqtalar yopiq halqa sifatida (yashil dala). */
  const farmlandGeoJSON = useMemo(() => ({
    type: 'FeatureCollection' as const,
    features: roads
      .filter((r) => r.kind === 'farmland' && r.points.length >= 3)
      .map((r) => {
        const ring = r.points.map(([lat, lng]) => [lng, lat] as [number, number]);
        // GeoJSON poligon halqasi yopiq bo'lishi kerak (birinchi = oxirgi).
        const [flng, flat] = ring[0];
        const [llng, llat] = ring[ring.length - 1];
        if (flng !== llng || flat !== llat) ring.push([flng, flat]);
        return {
          type: 'Feature' as const,
          id: r.id,
          geometry: { type: 'Polygon' as const, coordinates: [ring] },
          properties: {
            id: r.id,
            name: r.name,
            selected: r.id === selectedRoadId,
          },
        };
      }),
  }), [roads, selectedRoadId]);

  const placesGeoJSON = useMemo(() => ({
    type: 'FeatureCollection' as const,
    features: places.map((p) => {
      const cat = placeCategory(p.category);
      return {
        type: 'Feature' as const,
        id: p.id,
        geometry: { type: 'Point' as const, coordinates: [p.lng, p.lat] },
        properties: {
          id: p.id,
          label: p.label,
          color: cat.color,
          emoji: cat.emoji,
          selected: p.id === selectedPlaceId,
        },
      };
    }),
  }), [places, selectedPlaceId]);

  const placeDraftGeoJSON = useMemo(() => ({
    type: 'FeatureCollection' as const,
    features: placeDraft
      ? [{
          type: 'Feature' as const,
          id: 'place-draft',
          geometry: { type: 'Point' as const, coordinates: [placeDraft[1], placeDraft[0]] },
          properties: {},
        }]
      : [],
  }), [placeDraft]);

  const draftLineGeoJSON = useMemo(() => ({
    type: 'FeatureCollection' as const,
    features: draft.length >= 2
      ? [{
          type: 'Feature' as const,
          geometry: {
            type: 'LineString' as const,
            coordinates: draft.map(([lat, lng]) => [lng, lat] as [number, number]),
          },
          properties: {},
        }]
      : [],
  }), [draft]);

  const draftPointsGeoJSON = useMemo(() => ({
    type: 'FeatureCollection' as const,
    features: draft.map(([lat, lng], i) => ({
      type: 'Feature' as const,
      geometry: { type: 'Point' as const, coordinates: [lng, lat] },
      properties: { index: i + 1 },
    })),
  }), [draft]);

  /* ── Event handlers ── */

  const interactiveLayers = useMemo(
    () => (clickEnabled ? [] : [...ROAD_FILL_LAYERS, 'places-circle']),
    [clickEnabled],
  );

  const handleClick = useCallback((e: MapLayerMouseEvent) => {
    if (clickEnabled) {
      onMapClick(e.lngLat.lat, e.lngLat.lng);
      return;
    }
    const features = e.features;
    if (!features || features.length === 0) return;
    const f = features[0];
    const lid = f.layer.id;
    if (ROAD_FILL_LAYERS.includes(lid)) {
      const id = f.properties?.id;
      if (id) onSelectRoad(id);
    } else if (lid === 'places-circle') {
      const id = f.properties?.id;
      if (id) onSelectPlace(id);
    }
  }, [clickEnabled, onMapClick, onSelectRoad, onSelectPlace]);

  const handleMouseEnter = useCallback(() => {
    if (!clickEnabled) setCursor('pointer');
  }, [clickEnabled]);

  const handleMouseLeave = useCallback(() => {
    if (!clickEnabled) setCursor('grab');
  }, [clickEnabled]);

  /* ── Render ── */

  return (
    <div style={{ height: 560, borderRadius: 12, overflow: 'hidden' }}>
      <Map
        initialViewState={{ longitude: CENTER.longitude, latitude: CENTER.latitude, zoom: 14 }}
        maxBounds={BOUNDS}
        mapStyle={MAP_STYLE}
        cursor={clickEnabled ? 'crosshair' : cursor}
        interactiveLayerIds={interactiveLayers}
        onClick={handleClick}
        onMouseEnter={handleMouseEnter}
        onMouseLeave={handleMouseLeave}
        onZoom={(e) => setMapZoom(e.viewState.zoom)}
        style={{ width: '100%', height: '100%' }}
      >
        <NavigationControl position="top-right" />

        {/* Xizmat hududi chegarasi */}
        <Source id="areas" type="geojson" data={areasGeoJSON}>
          <Layer
            id="area-fill"
            type="fill"
            paint={{ 'fill-color': '#1e88e5', 'fill-opacity': 0.04 }}
          />
          <Layer
            id="area-line"
            type="line"
            paint={{ 'line-color': '#1e88e5', 'line-width': 1.5, 'line-dasharray': [6, 6] }}
          />
        </Source>

        {/* Dehqonchilik maydonlari — yashil poligonlar (yo'llar ostida) */}
        <Source id="farmland" type="geojson" data={farmlandGeoJSON}>
          <Layer
            id="farmland-fill"
            type="fill"
            paint={{
              'fill-color': '#66bb6a',
              'fill-opacity': [
                'case', ['==', ['get', 'selected'], true], 0.45, 0.28,
              ],
            }}
          />
          <Layer
            id="farmland-line"
            type="line"
            paint={{
              'line-color': [
                'case', ['==', ['get', 'selected'], true], '#facc15', '#2e7d32',
              ],
              'line-width': ['case', ['==', ['get', 'selected'], true], 3, 1.6],
              'line-dasharray': [4, 3],
            }}
          />
          <Layer
            id="farmland-label"
            type="symbol"
            minzoom={13}
            layout={{
              'text-field': ['get', 'name'],
              'text-size': 12,
              'text-font': ['Noto Sans Regular', 'Open Sans Regular', 'Arial Unicode MS Regular'],
            }}
            paint={{
              'text-color': '#1b5e20',
              'text-halo-color': 'rgba(255,255,255,0.95)',
              'text-halo-width': 2,
            }}
          />
        </Source>

        {/* Admin yo'llar — casing (kontur) */}
        <Source id="roads" type="geojson" data={roadsGeoJSON}>
          <Layer
            id="roads-casing"
            type="line"
            layout={{ 'line-cap': 'round', 'line-join': 'round' }}
            paint={{
              'line-color': [
                'match', ['get', 'kind'],
                'center', '#7c4600',
                'main',   '#a07a00',
                /* street */ '#b0bec5',
              ],
              'line-width': ['match', ['get', 'kind'], 'center', 9.5, 'main', 7, 5],
              'line-opacity': 0.9,
            }}
          />

          {/* Fill — normal yo'llar */}
          <Layer
            id="roads-fill-normal"
            type="line"
            filter={['all',
              ['!=', ['get', 'isRestricted'], true],
              ['!=', ['get', 'isUnderConstruction'], true],
            ]}
            layout={{ 'line-cap': 'round', 'line-join': 'round' }}
            paint={{
              'line-color': [
                'case', ['==', ['get', 'selected'], true],
                '#facc15',
                ['match', ['get', 'kind'], 'center', '#e8960c', 'main', '#f7bd3e', '#94a3b8'],
              ],
              'line-width': [
                'case', ['==', ['get', 'selected'], true],
                ['match', ['get', 'kind'], 'center', 9, 'main', 7, 5],
                ['match', ['get', 'kind'], 'center', 7, 'main', 5, 3],
              ],
              'line-opacity': ['case', ['==', ['get', 'selected'], true], 1, 0.85],
            }}
          />

          {/* Fill — cheklangan yo'llar (qisqa kesiklar) */}
          <Layer
            id="roads-fill-restricted"
            type="line"
            filter={['==', ['get', 'isRestricted'], true]}
            layout={{ 'line-cap': 'round', 'line-join': 'round' }}
            paint={{
              'line-color': [
                'case', ['==', ['get', 'selected'], true],
                '#facc15',
                ['match', ['get', 'kind'], 'center', '#e8960c', 'main', '#f7bd3e', '#94a3b8'],
              ],
              'line-width': ['match', ['get', 'kind'], 'center', 7, 'main', 5, 3],
              'line-dasharray': [2, 6],
              'line-opacity': 0.85,
            }}
          />

          {/* Fill — qurilish ostidagi yo'llar (uzun kesiklar) */}
          <Layer
            id="roads-fill-construction"
            type="line"
            filter={['==', ['get', 'isUnderConstruction'], true]}
            layout={{ 'line-cap': 'round', 'line-join': 'round' }}
            paint={{
              'line-color': [
                'case', ['==', ['get', 'selected'], true],
                '#facc15',
                ['match', ['get', 'kind'], 'center', '#e8960c', 'main', '#f7bd3e', '#94a3b8'],
              ],
              'line-width': ['match', ['get', 'kind'], 'center', 7, 'main', 5, 3],
              'line-dasharray': [10, 6],
              'line-opacity': 0.85,
            }}
          />
        </Source>

        {/* Joylar (oshxona/maktab/kasalxona ...) */}
        <Source id="places" type="geojson" data={placesGeoJSON}>
          <Layer
            id="places-circle"
            type="circle"
            paint={{
              // Zoom 12 dan 18 ga o'tganda kichrayadi (katta zoom = kichik belgi).
              // Bitta 'interpolate' ichida 'selected' bo'yicha case — MapLibre bir
              // paint xususiyatida bir nechta zoom-asosli interpolate'ga ruxsat bermaydi.
              'circle-radius': [
                'interpolate', ['linear'], ['zoom'],
                12, ['case', ['==', ['get', 'selected'], true], 13, 9],
                18, ['case', ['==', ['get', 'selected'], true], 9, 6],
              ],
              'circle-color': ['get', 'color'],
              'circle-stroke-color': [
                'case', ['==', ['get', 'selected'], true], '#1a202c', 'rgba(255,255,255,0.95)',
              ],
              'circle-stroke-width': ['case', ['==', ['get', 'selected'], true], 3, 2],
            }}
          />
          {/* Joy nomlari — zoom 13+ da ko'rinadi */}
          <Layer
            id="places-label"
            type="symbol"
            minzoom={13}
            layout={{
              'text-field': ['get', 'label'],
              'text-size': 12,
              'text-offset': [0, -1.8],
              'text-anchor': 'bottom',
              'text-max-width': 12,
              'text-font': ['Noto Sans Regular', 'Open Sans Regular', 'Arial Unicode MS Regular'],
              'text-allow-overlap': false,
            }}
            paint={{
              'text-color': '#1a202c',
              'text-halo-color': 'rgba(255,255,255,0.97)',
              'text-halo-width': 2.5,
            }}
          />
        </Source>

        {/* Admin belgilari (shop/sticker/construction ...) — HTML overlay, to'liq rangli emoji */}
        {markers.map((m) => {
          const isSelected = m.id === selectedMarkerId;
          const sz = isSelected ? emojiSizeSelected : emojiSizeNormal;
          return (
            <Marker
              key={m.id}
              longitude={m.lng}
              latitude={m.lat}
              anchor="center"
              onClick={() => { if (!clickEnabled) onSelectMarker?.(m.id); }}
            >
              <div
                style={{
                  fontSize: sz,
                  lineHeight: 1,
                  cursor: clickEnabled ? 'crosshair' : 'pointer',
                  userSelect: 'none',
                  pointerEvents: clickEnabled ? 'none' : 'auto',
                  filter: isSelected
                    ? 'drop-shadow(0 0 5px rgba(250,204,21,1)) drop-shadow(0 0 2px rgba(0,0,0,0.6))'
                    : 'drop-shadow(0 0 3px rgba(255,255,255,0.9)) drop-shadow(0 0 1px rgba(0,0,0,0.5))',
                  transition: 'font-size 200ms, filter 150ms',
                }}
              >
                {MARKER_EMOJI[m.kind] ?? '📌'}
              </div>
            </Marker>
          );
        })}

        {/* Yangi marker qo'yilayotgan nuqta — preview */}
        {pendingMarker && (
          <Marker
            longitude={pendingMarker[1]}
            latitude={pendingMarker[0]}
            anchor="center"
          >
            <div
              style={{
                fontSize: emojiSizeSelected,
                lineHeight: 1,
                userSelect: 'none',
                pointerEvents: 'none',
                filter: 'drop-shadow(0 0 5px rgba(250,204,21,1)) drop-shadow(0 0 2px rgba(0,0,0,0.6))',
              }}
            >
              {MARKER_EMOJI[pendingMarkerKind] ?? '📌'}
            </div>
          </Marker>
        )}

        {/* Joy qoralamasi (joy qo'shish rejimi — xaritaga bosib o'rnatilayotgan nuqta) */}
        <Source id="place-draft" type="geojson" data={placeDraftGeoJSON}>
          <Layer
            id="place-draft-circle"
            type="circle"
            paint={{
              'circle-radius': 10,
              'circle-color': 'rgba(255,255,255,0.85)',
              'circle-stroke-color': '#1a202c',
              'circle-stroke-width': 3,
            }}
          />
        </Source>

        {/* Yo'l qoralamasi — chizilayotgan chiziq */}
        <Source id="draft-line" type="geojson" data={draftLineGeoJSON}>
          <Layer
            id="draft-line-layer"
            type="line"
            layout={{ 'line-cap': 'round', 'line-join': 'round' }}
            paint={{
              'line-color': draftColor,
              'line-width': 3.5,
              'line-dasharray': [8, 6],
              'line-opacity': 0.9,
            }}
          />
        </Source>

        {/* Yo'l qoralamasi — har bir nuqta */}
        <Source id="draft-points" type="geojson" data={draftPointsGeoJSON}>
          <Layer
            id="draft-points-circle"
            type="circle"
            paint={{
              'circle-radius': 5,
              'circle-color': draftColor,
              'circle-stroke-color': '#fff',
              'circle-stroke-width': 2,
            }}
          />
          <Layer
            id="draft-points-label"
            type="symbol"
            layout={{
              'text-field': ['to-string', ['get', 'index']],
              'text-size': 10,
              'text-offset': [0, -1.5],
              'text-anchor': 'bottom',
              'text-font': ['Open Sans Semibold', 'Arial Unicode MS Regular'],
              'text-allow-overlap': true,
            }}
            paint={{
              'text-color': '#1a202c',
              'text-halo-color': '#fff',
              'text-halo-width': 2,
            }}
          />
        </Source>
      </Map>
    </div>
  );
}
