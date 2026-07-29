import type { RoadKind } from './types';

/**
 * Yo'l ko'rinishi — Flutter (customer_app/lib/core/map_road.dart) bilan mos.
 * Markaziy: to'q amber, Asosiy: sariq, Ko'cha: kulrang.
 */
export const ROAD_COLORS: Record<RoadKind, string> = {
  center: '#e8960c', // to'q amber — magistral
  main:   '#f7bd3e', // sariq — asosiy yo'l
  street: '#94a3b8', // kulrang — mahalla ko'chasi
  farmland: '#66bb6a', // yashil — dehqonchilik maydoni (poligon)
};

// Casing ranglari (yo'l konturi) — to'qroq soyasi.
export const ROAD_CASING: Record<RoadKind, string> = {
  center: '#7c4600',
  main:   '#a07a00',
  street: '#e2e8f0',
  farmland: '#2e7d32',
};

export const ROAD_WIDTH: Record<RoadKind, number> = {
  center: 5,
  main:   3.5,
  street: 2.5,
  farmland: 1.5,
};

export const ROAD_KIND_LABELS: Record<RoadKind, string> = {
  street: "Ko'cha",
  main: 'Asosiy yo\'l',
  center: 'Markaziy ko\'cha',
  farmland: 'Dala (dehqonchilik)',
};

export const ROAD_KINDS: RoadKind[] = ['street', 'main', 'center', 'farmland'];

export const BESHARIQ_CENTER: [number, number] = [40.4236, 70.6094];
export const BESHARIQ_BOUNDS: [[number, number], [number, number]] = [
  [40.36, 70.52],
  [40.52, 70.74],
];
