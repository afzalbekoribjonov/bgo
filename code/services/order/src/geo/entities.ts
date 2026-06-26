import { PolygonCoords } from '../common/polygon';

export interface Place {
  id: string;
  areaId: string;
  label: string;
  lat: number;
  lng: number;
  category?: string;
  sortOrder: number;
}

export interface ServiceArea {
  id: string;
  name: string;
  centerLat: number;
  centerLng: number;
  boundary: PolygonCoords;
  isActive: boolean;
}

export interface ServiceAreaWithPlaces extends ServiceArea {
  places: Place[];
}

/** Yo'l chizig'i turi — klient rangni shu bo'yicha tanlaydi. */
export type RoadKind = 'street' | 'main' | 'center';

export interface MapRoad {
  id: string;
  areaId: string;
  name: string;
  kind: RoadKind;
  /** [[lat, lng], ...] */
  points: number[][];
}

export interface NewMapRoad {
  areaId: string;
  name: string;
  kind: RoadKind;
  points: number[][];
}

export interface NewServiceArea {
  name: string;
  centerLat: number;
  centerLng: number;
  boundary: PolygonCoords;
  isActive?: boolean;
}

export interface NewPlace {
  areaId: string;
  label: string;
  lat: number;
  lng: number;
  category?: string;
  sortOrder?: number;
}
