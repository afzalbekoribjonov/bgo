import {
  MapRoad,
  NewMapRoad,
  NewPlace,
  NewServiceArea,
  Place,
  ServiceArea,
  ServiceAreaWithPlaces,
} from './entities';

/** Xizmat hududlari + joylar + yo'llar repository (abstrakt). */
export abstract class GeoRepository {
  abstract listAreas(activeOnly: boolean): Promise<ServiceAreaWithPlaces[]>;
  abstract findArea(id: string): Promise<ServiceArea | null>;
  abstract createArea(data: NewServiceArea): Promise<ServiceArea>;
  abstract updateArea(
    id: string,
    patch: Partial<NewServiceArea>,
  ): Promise<ServiceArea>;
  abstract deleteArea(id: string): Promise<void>;

  abstract listPlaces(areaId: string): Promise<Place[]>;
  abstract createPlace(data: NewPlace): Promise<Place>;
  abstract deletePlace(id: string): Promise<void>;

  /** Yo'llar — activeOnly: faqat faol hududlarniki. */
  abstract listRoads(activeOnly: boolean): Promise<MapRoad[]>;
  abstract createRoad(data: NewMapRoad): Promise<MapRoad>;
  abstract deleteRoad(id: string): Promise<void>;
  abstract roadCount(): Promise<number>;

  abstract areaCount(): Promise<number>;
}
