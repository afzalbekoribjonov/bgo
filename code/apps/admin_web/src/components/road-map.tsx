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
import type { MapRoad, RoadKind, ServiceArea } from '@/lib/types';

type LatLng = [number, number];

/** Xarita bosilishini ushlaydi — chizish rejimida nuqta qo'shadi. */
function ClickCatcher({
  enabled,
  onAdd,
}: {
  enabled: boolean;
  onAdd: (lat: number, lng: number) => void;
}) {
  useMapEvents({
    click(e) {
      if (enabled) onAdd(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

export interface RoadMapProps {
  roads: MapRoad[];
  areas: ServiceArea[];
  draft: LatLng[];
  draftKind: RoadKind;
  drawing: boolean;
  selectedRoadId: string | null;
  onAddPoint: (lat: number, lng: number) => void;
  onSelectRoad: (id: string) => void;
}

export default function RoadMap({
  roads,
  areas,
  draft,
  draftKind,
  drawing,
  selectedRoadId,
  onAddPoint,
  onSelectRoad,
}: RoadMapProps) {
  const draftColor = ROAD_COLORS[draftKind];

  return (
    <MapContainer
      center={BESHARIQ_CENTER}
      zoom={14}
      minZoom={12}
      maxBounds={BESHARIQ_BOUNDS}
      maxBoundsViscosity={1}
      className={drawing ? 'road-map drawing' : 'road-map'}
      style={{ height: 540, width: '100%', borderRadius: 12 }}
    >
      <TileLayer
        url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution="&copy; OpenStreetMap"
        maxZoom={19}
      />

      {/* Hudud chegaralari (kontekst uchun) */}
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

      {/* Joylar (mo'ljallar) */}
      {areas
        .flatMap((a) => a.places)
        .map((p) => (
          <CircleMarker
            key={p.id}
            center={[p.lat, p.lng]}
            radius={4}
            pathOptions={{
              color: '#0d47a1',
              fillColor: '#42a5f5',
              fillOpacity: 1,
              weight: 1,
            }}
          >
            <Tooltip direction="top">{p.label}</Tooltip>
          </CircleMarker>
        ))}

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

      <ClickCatcher enabled={drawing} onAdd={onAddPoint} />
    </MapContainer>
  );
}
