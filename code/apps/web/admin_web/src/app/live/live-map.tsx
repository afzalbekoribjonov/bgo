'use client';

import { useEffect, useRef, useState } from 'react';
import Map, { Marker, NavigationControl } from 'react-map-gl/maplibre';
import type { MapRef } from 'react-map-gl/maplibre';
import 'maplibre-gl/dist/maplibre-gl.css';
import { getLiveDrivers } from '@/lib/api';
import type { LiveDriver, LiveDrivers } from '@/lib/types';

const MAP_STYLE = 'https://tiles.openfreemap.org/styles/liberty';
const CENTER = { longitude: 70.6094, latitude: 40.4236 };
const POLL_MS = 2500; // yangi joylashuvlarni olish oralig'i
const ANIM_MS = 2300; // ikki poll orasida silliq siljish davomiyligi

/** Ranglar: band (faol buyurtmada) — brend olov; bo'sh — yashil. */
const BUSY_COLOR = '#F4511E';
const FREE_COLOR = '#2E7D32';

/** Ekranda animatsiya qilinadigan mashina holati. */
interface CarState {
  driver: LiveDriver;
  // Joriy (chizilayotgan) va maqsad koordinatalar — rAF lerp.
  curLat: number;
  curLng: number;
  fromLat: number;
  fromLng: number;
  toLat: number;
  toLng: number;
  heading: number;
  animStart: number;
}

/** Ikki nuqta orasidagi harakat yo'nalishi (gradus, 0=shimol). */
function bearing(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = Math.PI / 180;
  const dLng = (lng2 - lng1) * toRad;
  const y = Math.sin(dLng) * Math.cos(lat2 * toRad);
  const x =
    Math.cos(lat1 * toRad) * Math.sin(lat2 * toRad) -
    Math.sin(lat1 * toRad) * Math.cos(lat2 * toRad) * Math.cos(dLng);
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
}

/** Tepadan ko'rinishdagi avtomobil (SVG) — xarita tekisligida yotadi. */
function CarIcon({ color, busy }: { color: string; busy: boolean }) {
  return (
    <div style={{ position: 'relative', width: 34, height: 56 }}>
      {busy && <span className="live-pulse" />}
      <svg
        width="34"
        height="56"
        viewBox="0 0 34 56"
        style={{ filter: 'drop-shadow(0 4px 6px rgba(0,0,0,.45))' }}
      >
        {/* Kuzov */}
        <path
          d="M7 12 Q7 3 17 3 Q27 3 27 12 L27 44 Q27 53 17 53 Q7 53 7 44 Z"
          fill={color}
          stroke="#ffffff"
          strokeWidth="2.2"
        />
        {/* Old oyna */}
        <path
          d="M10 15 Q17 11 24 15 L23 23 Q17 20 11 23 Z"
          fill="rgba(255,255,255,0.9)"
        />
        {/* Tom chizig'i */}
        <rect x="11" y="26" width="12" height="12" rx="3" fill="rgba(0,0,0,0.12)" />
        {/* Orqa oyna */}
        <path
          d="M11 41 Q17 44 23 41 L24 47 Q17 51 10 47 Z"
          fill="rgba(255,255,255,0.65)"
        />
        {/* Faralar */}
        <circle cx="11" cy="6.5" r="1.6" fill="#FFF59D" />
        <circle cx="23" cy="6.5" r="1.6" fill="#FFF59D" />
      </svg>
    </div>
  );
}

export default function LiveMap() {
  const mapRef = useRef<MapRef | null>(null);
  const [cars, setCars] = useState<Map0<string, CarState>>(new Map0());
  const [counts, setCounts] = useState({ online: 0, busy: 0, free: 0 });
  const [selected, setSelected] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);
  const carsRef = useRef(cars);
  carsRef.current = cars;

  // Yangi ma'lumot kelganda maqsad nuqtalarni yangilaymiz (silliq o'tish).
  useEffect(() => {
    let stop = false;
    async function poll() {
      try {
        const data: LiveDrivers = await getLiveDrivers();
        if (stop) return;
        setCounts(data.counts);
        setLastUpdate(new Date());
        setCars((prev) => {
          const next = new Map0<string, CarState>();
          const now = performance.now();
          for (const d of data.drivers) {
            const old = prev.get(d.driverId);
            if (old) {
              // Yo'nalish: serverdan; bo'lmasa harakatdan hisoblaymiz.
              const moved =
                Math.abs(old.toLat - d.lat) > 1e-6 ||
                Math.abs(old.toLng - d.lng) > 1e-6;
              const h =
                d.heading ??
                (moved
                  ? bearing(old.toLat, old.toLng, d.lat, d.lng)
                  : old.heading);
              next.set(d.driverId, {
                driver: d,
                curLat: old.curLat,
                curLng: old.curLng,
                fromLat: old.curLat,
                fromLng: old.curLng,
                toLat: d.lat,
                toLng: d.lng,
                heading: h,
                animStart: now,
              });
            } else {
              next.set(d.driverId, {
                driver: d,
                curLat: d.lat,
                curLng: d.lng,
                fromLat: d.lat,
                fromLng: d.lng,
                toLat: d.lat,
                toLng: d.lng,
                heading: d.heading ?? 0,
                animStart: now,
              });
            }
          }
          return next;
        });
      } catch {
        /* poll xatosi — keyingi urinish */
      }
    }
    poll();
    const t = setInterval(poll, POLL_MS);
    return () => {
      stop = true;
      clearInterval(t);
    };
  }, []);

  // rAF — mashinalarni maqsad nuqtaga silliq siljitish (haqiqiy harakat hissi).
  useEffect(() => {
    let raf = 0;
    const tick = () => {
      const now = performance.now();
      let changed = false;
      const cur = carsRef.current;
      const next = new Map0<string, CarState>();
      for (const [id, c] of cur) {
        const t = Math.min(1, (now - c.animStart) / ANIM_MS);
        const e = 1 - Math.pow(1 - t, 2); // ease-out
        const lat = c.fromLat + (c.toLat - c.fromLat) * e;
        const lng = c.fromLng + (c.toLng - c.fromLng) * e;
        if (Math.abs(lat - c.curLat) > 1e-8 || Math.abs(lng - c.curLng) > 1e-8) {
          changed = true;
        }
        next.set(id, { ...c, curLat: lat, curLng: lng });
      }
      if (changed) setCars(next);
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, []);

  const sel = selected ? cars.get(selected) : null;

  return (
    <div style={{ position: 'relative', height: '100%', borderRadius: 14, overflow: 'hidden' }}>
      {/* Pulsatsiya CSS */}
      <style>{`
        .live-pulse {
          position: absolute; inset: -10px; border-radius: 50%;
          background: radial-gradient(circle, rgba(244,81,30,0.35) 0%, rgba(244,81,30,0) 70%);
          animation: livePulse 1.6s ease-out infinite;
        }
        @keyframes livePulse {
          0% { transform: scale(0.6); opacity: 1; }
          100% { transform: scale(1.5); opacity: 0; }
        }
        .live-chip {
          display: flex; align-items: center; gap: 10px;
          background: rgba(15, 23, 42, 0.82); backdrop-filter: blur(8px);
          border: 1px solid rgba(255,255,255,0.12);
          border-radius: 14px; padding: 10px 16px; color: #fff;
        }
        .live-chip-num { font-size: 22px; font-weight: 800; line-height: 1; }
        .live-chip-lbl { font-size: 11px; opacity: .75; font-weight: 600; }
        .live-dot { width: 10px; height: 10px; border-radius: 50%; }
      `}</style>

      <Map
        ref={mapRef}
        initialViewState={{
          longitude: CENTER.longitude,
          latitude: CENTER.latitude,
          zoom: 13.6,
          pitch: 55,
          bearing: -12,
        }}
        mapStyle={MAP_STYLE}
        style={{ width: '100%', height: '100%' }}
      >
        <NavigationControl position="bottom-right" visualizePitch />
        {[...cars.values()].map((c) => (
          <Marker
            key={c.driver.driverId}
            longitude={c.curLng}
            latitude={c.curLat}
            rotation={c.heading}
            rotationAlignment="map"
            pitchAlignment="map"
            anchor="center"
            onClick={(e) => {
              e.originalEvent.stopPropagation();
              setSelected(
                selected === c.driver.driverId ? null : c.driver.driverId,
              );
            }}
            style={{ cursor: 'pointer' }}
          >
            <CarIcon
              color={c.driver.busy ? BUSY_COLOR : FREE_COLOR}
              busy={c.driver.busy}
            />
          </Marker>
        ))}
      </Map>

      {/* Yuqori statistika paneli */}
      <div
        style={{
          position: 'absolute',
          top: 14,
          left: 14,
          right: 14,
          display: 'flex',
          gap: 10,
          flexWrap: 'wrap',
          pointerEvents: 'none',
        }}
      >
        <div className="live-chip">
          <span className="live-dot" style={{ background: '#38bdf8' }} />
          <div>
            <div className="live-chip-num">{counts.online}</div>
            <div className="live-chip-lbl">ONLINE HAYDOVCHI</div>
          </div>
        </div>
        <div className="live-chip">
          <span className="live-dot" style={{ background: BUSY_COLOR }} />
          <div>
            <div className="live-chip-num" style={{ color: '#ffab91' }}>
              {counts.busy}
            </div>
            <div className="live-chip-lbl">FAOL BUYURTMADA</div>
          </div>
        </div>
        <div className="live-chip">
          <span className="live-dot" style={{ background: FREE_COLOR }} />
          <div>
            <div className="live-chip-num" style={{ color: '#a5d6a7' }}>
              {counts.free}
            </div>
            <div className="live-chip-lbl">BO&apos;SH (BUYURTMASIZ)</div>
          </div>
        </div>
        {lastUpdate && (
          <div className="live-chip" style={{ marginLeft: 'auto' }}>
            <span
              className="live-dot"
              style={{ background: '#4ade80', animation: 'livePulse 1.6s infinite' }}
            />
            <div>
              <div style={{ fontSize: 12.5, fontWeight: 700 }}>JONLI</div>
              <div className="live-chip-lbl">
                {lastUpdate.toLocaleTimeString('uz-UZ')}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Tanlangan mashina kartasi */}
      {sel && (
        <div
          style={{
            position: 'absolute',
            bottom: 18,
            left: 14,
            background: 'rgba(15, 23, 42, 0.88)',
            backdropFilter: 'blur(8px)',
            border: '1px solid rgba(255,255,255,0.14)',
            borderRadius: 14,
            padding: '14px 18px',
            color: '#fff',
            minWidth: 240,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
            <span
              className="live-dot"
              style={{ background: sel.driver.busy ? BUSY_COLOR : FREE_COLOR }}
            />
            <span style={{ fontWeight: 800, fontSize: 15 }}>
              {sel.driver.name ?? 'Haydovchi'}
            </span>
          </div>
          <div style={{ fontSize: 13, opacity: 0.85 }}>
            {sel.driver.car ?? '—'}
            {sel.driver.plate ? ` · ${sel.driver.plate}` : ''}
          </div>
          <div
            style={{
              marginTop: 8,
              display: 'inline-block',
              padding: '4px 12px',
              borderRadius: 20,
              fontSize: 12,
              fontWeight: 800,
              background: sel.driver.busy
                ? 'rgba(244,81,30,0.25)'
                : 'rgba(46,125,50,0.3)',
              color: sel.driver.busy ? '#ffab91' : '#a5d6a7',
            }}
          >
            {sel.driver.busy ? '🔥 Faol buyurtmada' : '✅ Bo\'sh — buyurtma kutmoqda'}
          </div>
        </div>
      )}
    </div>
  );
}

/**
 * JS Map uchun qisqa taxallus — React'ning Map (xarita) komponenti bilan nom
 * to'qnashuvining oldini oladi.
 */
class Map0<K, V> extends globalThis.Map<K, V> {}
