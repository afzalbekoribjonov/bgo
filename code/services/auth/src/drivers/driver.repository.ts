import {
  DriverProfileEntity,
  DriverProfilePatch,
  DriverTopupEntity,
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

  /** Hisobni to'ldirish (balansga qo'shadi + tarix yozadi). */
  abstract topup(
    driverId: string,
    amount: number,
    note?: string,
  ): Promise<DriverProfileEntity>;
  abstract listTopups(driverId: string): Promise<DriverTopupEntity[]>;
}
