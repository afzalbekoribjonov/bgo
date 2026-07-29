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

/**
 * Yo'l chizig'i turi — klient rangni shu bo'yicha tanlaydi.
 * 'farmland' — dehqonchilik maydoni: chiziq emas, yopiq poligon (yashil dala).
 */
export type RoadKind = 'street' | 'main' | 'center' | 'farmland';

export interface MapRoad {
  id: string;
  areaId: string;
  name: string;
  kind: RoadKind;
  /** [[lat, lng], ...] */
  points: number[][];
  isOneWay: boolean;
  isUnderConstruction: boolean;
  hasTrafficLight: boolean;
  isRestricted: boolean;
  speedLimit: number | null;
}

export interface NewMapRoad {
  areaId: string;
  name: string;
  kind: RoadKind;
  points: number[][];
  isOneWay?: boolean;
  isUnderConstruction?: boolean;
  hasTrafficLight?: boolean;
  isRestricted?: boolean;
  speedLimit?: number | null;
}

export type MarkerKind =
  | 'shop'
  | 'sticker'
  | 'construction'
  | 'traffic_light'
  | 'restriction'
  | 'farm';

export interface MapMarker {
  id: string;
  areaId: string;
  lat: number;
  lng: number;
  kind: MarkerKind;
  label: string | null;
  color: string | null;
}

export interface NewMapMarker {
  areaId: string;
  lat: number;
  lng: number;
  kind: MarkerKind;
  label?: string | null;
  color?: string | null;
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
