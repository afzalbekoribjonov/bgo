'use client';

import {
  CircleMarker,
  MapContainer,
  Polygon,
  Polyline,
  TileLayer,
  Tooltip,
  useMapEvents,
} from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import {
  BESHARIQ_BOUNDS,
  BESHARIQ_CENTER,
  ROAD_COLORS,
  ROAD_WIDTH,
} from '@/lib/road-style';
import { placeCategory } from '@/lib/place-style';
import type { MapRoad, RoadKind, ServiceArea } from '@/lib/types';

type LatLng = [number, number];

/** Xarita bosilishini ushlaydi — chizish/joy rejimida nuqta beradi. */
function ClickCatcher({
  enabled,
  onClick,
}: {
  enabled: boolean;
  onClick: (lat: number, lng: number) => void;
}) {
  useMapEvents({
    click(e) {
      if (enabled) onClick(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

export interface RoadMapProps {
  roads: MapRoad[];
  areas: ServiceArea[];
  draft: LatLng[];
  draftKind: RoadKind;
  clickEnabled: boolean;
  selectedRoadId: string | null;
  selectedPlaceId: string | null;
  placeDraft: LatLng | null;
  onMapClick: (lat: number, lng: number) => void;
  onSelectRoad: (id: string) => void;
  onSelectPlace: (id: string) => void;
}

export default function RoadMap({
  roads,
  areas,
  draft,
  draftKind,
  clickEnabled,
  selectedRoadId,
  selectedPlaceId,
  placeDraft,
  onMapClick,
  onSelectRoad,
  onSelectPlace,
}: RoadMapProps) {
  const draftColor = ROAD_COLORS[draftKind];
  const places = areas.flatMap((a) => a.places);

  return (
    <MapContainer
      center={BESHARIQ_CENTER}
      zoom={14}
      minZoom={12}
      maxBounds={BESHARIQ_BOUNDS}
      maxBoundsViscosity={1}
      className={clickEnabled ? 'road-map drawing' : 'road-map'}
      style={{ height: 560, width: '100%', borderRadius: 12 }}
    >
      <TileLayer
        url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution="&copy; OpenStreetMap"
        maxZoom={19}
      />

      {/* Hudud chegaralari */}
      {areas.map((a) =>
        a.boundary.map((ring, i) => (
          <Polygon
            key={`${a.id}-${i}`}
            positions={ring.map(([lng, lat]) => [lat, lng] as LatLng)}
            pathOptions={{
              color: '#1e88e5',
              weight: 1.5,
              fillOpacity: 0.03,
              dashArray: '6 6',
            }}
          />
        )),
      )}

      {/* Mavjud yo'llar */}
      {roads.map((r) => {
        const selected = r.id === selectedRoadId;
        return (
          <Polyline
            key={r.id}
            positions={r.points.map(([lat, lng]) => [lat, lng] as LatLng)}
            pathOptions={{
              color: ROAD_COLORS[r.kind] ?? ROAD_COLORS.street,
              weight: (ROAD_WIDTH[r.kind] ?? 3.5) + (selected ? 3 : 0),
              opacity: selected ? 1 : 0.85,
            }}
            eventHandlers={{ click: () => onSelectRoad(r.id) }}
          >
            <Tooltip sticky>{r.name}</Tooltip>
          </Polyline>
        );
      })}

      {/* Joylar (turi bo'yicha rangli) */}
      {places.map((p) => {
        const cat = placeCategory(p.category);
        const selected = p.id === selectedPlaceId;
        return (
          <CircleMarker
            key={p.id}
            center={[p.lat, p.lng]}
            radius={selected ? 9 : 6}
            pathOptions={{
              color: selected ? '#1a202c' : '#ffffff',
              fillColor: cat.color,
              fillOpacity: 1,
              weight: selected ? 3 : 1.5,
            }}
            eventHandlers={{ click: () => onSelectPlace(p.id) }}
          >
            <Tooltip direction="top">
              {cat.emoji} {p.label}
            </Tooltip>
          </CircleMarker>
        );
      })}

      {/* Yangi joy (qoralama) */}
      {placeDraft && (
        <CircleMarker
          center={placeDraft}
          radius={10}
          pathOptions={{
            color: '#1a202c',
            fillColor: '#fff',
            fillOpacity: 0.9,
            weight: 3,
            dashArray: '4 4',
          }}
        >
          <Tooltip permanent direction="top">
            Yangi joy — saqlang
          </Tooltip>
        </CircleMarker>
      )}

      {/* Chizilayotgan yo'l (qoralama) */}
      {draft.length >= 2 && (
        <Polyline
          positions={draft}
          pathOptions={{ color: draftColor, weight: 4, dashArray: '8 6' }}
        />
      )}
      {draft.map((pt, i) => (
        <CircleMarker
          key={`draft-${i}`}
          center={pt}
          radius={5}
          pathOptions={{
            color: '#fff',
            fillColor: draftColor,
            fillOpacity: 1,
            weight: 2,
          }}
        >
          <Tooltip permanent direction="top">
            {i + 1}
          </Tooltip>
        </CircleMarker>
      ))}

      <ClickCatcher enabled={clickEnabled} onClick={onMapClick} />
    </MapContainer>
  );
}
