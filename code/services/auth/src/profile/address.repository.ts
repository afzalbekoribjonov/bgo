import { Address, AddressPatch, NewAddress } from './address.entity';

/** Manzillar repository interfeysi (abstrakt). */
export abstract class AddressRepository {
  abstract findByUser(userId: string): Promise<Address[]>;
  abstract findById(id: string): Promise<Address | null>;
  abstract create(data: NewAddress): Promise<Address>;
  abstract update(id: string, patch: AddressPatch): Promise<Address>;
  abstract delete(id: string): Promise<void>;
  /** Foydalanuvchining barcha manzillaridan standart belgisini olib tashlaydi. */
  abstract clearDefault(userId: string): Promise<void>;
}
