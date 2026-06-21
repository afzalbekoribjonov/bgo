import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { UserRepository } from '../users/user.repository';
import { CreateAddressDto, UpdateAddressDto } from './dto/address.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { AddressRepository } from './address.repository';

/** Mijoz profili (ism/til) + saqlangan manzillar. plan/05-customer-app.md */
@Injectable()
export class ProfileService {
  constructor(
    private readonly users: UserRepository,
    private readonly addresses: AddressRepository,
  ) {}

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.users.update(userId, {
      ...(dto.fullName !== undefined ? { fullName: dto.fullName } : {}),
      ...(dto.locale !== undefined ? { locale: dto.locale } : {}),
    });
    return {
      id: user.id,
      phone: user.phone,
      fullName: user.fullName ?? null,
      locale: user.locale,
      roles: user.roles,
    };
  }

  listAddresses(userId: string) {
    return this.addresses.findByUser(userId);
  }

  async addAddress(userId: string, dto: CreateAddressDto) {
    const existing = await this.addresses.findByUser(userId);
    // Birinchi manzil avtomatik standart bo'ladi.
    const isDefault = dto.isDefault ?? existing.length === 0;
    if (isDefault) await this.addresses.clearDefault(userId);
    return this.addresses.create({
      userId,
      label: dto.label,
      text: dto.text,
      lat: dto.lat,
      lng: dto.lng,
      isDefault,
    });
  }

  async updateAddress(userId: string, id: string, dto: UpdateAddressDto) {
    await this.requireOwned(userId, id);
    if (dto.isDefault === true) await this.addresses.clearDefault(userId);
    return this.addresses.update(id, dto);
  }

  async deleteAddress(userId: string, id: string) {
    await this.requireOwned(userId, id);
    await this.addresses.delete(id);
  }

  private async requireOwned(userId: string, id: string) {
    const addr = await this.addresses.findById(id);
    if (!addr) throw new NotFoundException('Manzil topilmadi');
    if (addr.userId !== userId) {
      throw new ForbiddenException('Bu manzil sizga tegishli emas');
    }
    return addr;
  }
}
