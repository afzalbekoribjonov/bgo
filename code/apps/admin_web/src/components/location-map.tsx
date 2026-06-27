'use client';

import { MapContainer, Marker, TileLayer, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { BESHARIQ_BOUNDS, BESHARIQ_CENTER } from '@/lib/road-style';

// Leaflet standart ikon (rasm asset) bundlerda buziladi — emoji divIcon ishlatamiz.
const pinIcon = L.divIcon({
  className: '',
  html: '<div style="font-size:30px;line-height:1;filter:drop-shadow(0 1px 2px rgba(0,0,0,.4))">📍</div>',
  iconSize: [30, 30],
  iconAnchor: [15, 28],
});

function ClickSetter({ onPick }: { onPick: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      onPick(Number(e.latlng.lat.toFixed(6)), Number(e.latlng.lng.toFixed(6)));
    },
  });
  return null;
}

/** Oshxona joylashuvini xaritadan tanlash — bosilgan nuqtaga marker qo'yadi. */
export default function LocationMap({
  lat,
  lng,
  onPick,
}: {
  lat: number;
  lng: number;
  onPick: (lat: number, lng: number) => void;
}) {
  const center: [number, number] =
    lat && lng ? [lat, lng] : BESHARIQ_CENTER;
  return (
    <MapContainer
      center={center}
      zoom={15}
      minZoom={12}
      maxBounds={BESHARIQ_BOUNDS}
      maxBoundsViscosity={1}
      style={{ height: 360, width: '100%', borderRadius: 12 }}
    >
      <TileLayer
        url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution="&copy; OpenStreetMap"
        maxZoom={19}
      />
      {lat !== 0 && lng !== 0 && (
        <Marker position={[lat, lng]} icon={pinIcon} />
      )}
      <ClickSetter onPick={onPick} />
    </MapContainer>
  );
}
