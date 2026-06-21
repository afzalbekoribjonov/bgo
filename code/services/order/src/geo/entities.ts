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
