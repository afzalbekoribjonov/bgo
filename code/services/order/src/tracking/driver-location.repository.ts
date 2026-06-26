import { DriverLocation, NewDriverLocation } from './entities';

/** Haydovchi joylashuvi repository (abstrakt). */
export abstract class DriverLocationRepository {
  /** Joylashuvni yangilaydi (upsert — har haydovchiga bitta qator). */
  abstract upsert(
    driverId: string,
    data: NewDriverLocation,
  ): Promise<DriverLocation>;
  abstract find(driverId: string): Promise<DriverLocation | null>;
  abstract remove(driverId: string): Promise<void>;
  /** `since` dan keyin yangilangan (online) joylashuvlar. */
  abstract listSince(since: Date): Promise<DriverLocation[]>;
}
