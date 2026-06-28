import {
  DriverProfileEntity,
  DriverProfilePatch,
  NewDriverProfile,
} from './driver.entity';

/** Haydovchi profillari ombori (abstrakt). plan/03-databases.md */
export abstract class DriverRepository {
  abstract findAll(): Promise<DriverProfileEntity[]>;
  abstract findById(id: string): Promise<DriverProfileEntity | null>;
  abstract findByPhone(phone: string): Promise<DriverProfileEntity | null>;
  abstract create(data: NewDriverProfile): Promise<DriverProfileEntity>;
  abstract update(
    id: string,
    patch: DriverProfilePatch,
  ): Promise<DriverProfileEntity>;
  abstract delete(id: string): Promise<void>;
}
