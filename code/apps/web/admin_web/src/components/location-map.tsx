'use client';

import { useCallback } from 'react';
import Map, { Marker, NavigationControl } from 'react-map-gl/maplibre';
import type { MapLayerMouseEvent } from 'react-map-gl/maplibre';
import 'maplibre-gl/dist/maplibre-gl.css';

// Oldingi chegara (~18×18 km) chekka qishloqlarga pin qo'yishga imkon
// bermasdi. Endi butun tuman + qo'shni hududlar uchun keng zaxira bilan.
// [g'arb, janub, sharq, shimol] — react-map-gl'ning maxBounds propi aynan
// shu yassi 4-tuple shaklini kutadi (LngLatBoundsLike'ning boshqa
// variantlari — masalan ichma-ich juftlik — bilan mos kelmaydi).
const BOUNDS: [number, number, number, number] = [70.1094, 40.1236, 71.1094, 40.7236];
const CENTER = { longitude: 70.6094, latitude: 40.4236 };
const MAP_STYLE = 'https://tiles.openfreemap.org/styles/liberty';

/** Oshxona joylashuvini xaritadan tanlash — bosilgan nuqtaga 📍 qo'yadi. */
export default function LocationMap({
  lat,
  lng,
  onPick,
}: {
  lat: number;
  lng: number;
  onPick: (lat: number, lng: number) => void;
}) {
  const hasPin = lat !== 0 && lng !== 0;
  const initial = hasPin
    ? { longitude: lng, latitude: lat, zoom: 15 }
    : { longitude: CENTER.longitude, latitude: CENTER.latitude, zoom: 14 };

  const handleClick = useCallback(
    (e: MapLayerMouseEvent) => {
      onPick(
        parseFloat(e.lngLat.lat.toFixed(6)),
        parseFloat(e.lngLat.lng.toFixed(6)),
      );
    },
    [onPick],
  );

  return (
    <div style={{ height: 360, borderRadius: 12, overflow: 'hidden' }}>
      <Map
        initialViewState={initial}
        maxBounds={BOUNDS}
        mapStyle={MAP_STYLE}
        cursor="crosshair"
        onClick={handleClick}
        style={{ width: '100%', height: '100%' }}
      >
        <NavigationControl position="top-right" />
        {hasPin && (
          <Marker longitude={lng} latitude={lat} anchor="bottom">
            <span style={{ fontSize: 30, lineHeight: 1, filter: 'drop-shadow(0 1px 2px rgba(0,0,0,.4))' }}>
              📍
            </span>
          </Marker>
        )}
      </Map>
    </div>
  );
}
