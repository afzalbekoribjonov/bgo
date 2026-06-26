import type { RoadKind } from './types';

/**
 * Yo'l ko'rinishi — mijoz ilovasidagi rang/qalinlik bilan bir xil
 * (customer_app/lib/core/map_road.dart). Leaflet import qilmaydi, shuning
 * uchun server bundle'ga xavfsiz.
 */
export const ROAD_COLORS: Record<RoadKind, string> = {
  center: '#ff7043', // markaziy — qizg'ish
  main: '#2e7d32', // asosiy — to'q yashil
  street: '#4caf50', // ko'cha — yashil
};

export const ROAD_WIDTH: Record<RoadKind, number> = {
  center: 6,
  main: 5,
  street: 3.5,
};

export const ROAD_KIND_LABELS: Record<RoadKind, string> = {
  street: "Ko'cha",
  main: 'Asosiy yo\'l',
  center: 'Markaziy ko\'cha',
};

export const ROAD_KINDS: RoadKind[] = ['street', 'main', 'center'];

/** Beshariq markazi va xarita chegarasi (mijoz ilovasi bilan bir xil). */
export const BESHARIQ_CENTER: [number, number] = [40.4236, 70.6094];
export const BESHARIQ_BOUNDS: [[number, number], [number, number]] = [
  [40.36, 70.52],
  [40.52, 70.74],
];
