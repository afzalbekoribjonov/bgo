import {
  NewPlace,
  NewServiceArea,
  Place,
  ServiceArea,
  ServiceAreaWithPlaces,
} from './entities';

/** Xizmat hududlari + joylar repository (abstrakt). */
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

  abstract areaCount(): Promise<number>;
}
