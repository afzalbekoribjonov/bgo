import { Injectable } from '@nestjs/common';
import { Address as PrismaAddress } from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import { Address, AddressPatch, NewAddress } from './address.entity';
import { AddressRepository } from './address.repository';

/** PostgreSQL (auth_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaAddressRepository extends AddressRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async findByUser(userId: string): Promise<Address[]> {
    const rows = await this.prisma.address.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
    return rows.map((r) => this.toEntity(r));
  }

  async findById(id: string): Promise<Address | null> {
    const row = await this.prisma.address.findUnique({ where: { id } });
    return row ? this.toEntity(row) : null;
  }

  async create(data: NewAddress): Promise<Address> {
    const row = await this.prisma.address.create({ data });
    return this.toEntity(row);
  }

  async update(id: string, patch: AddressPatch): Promise<Address> {
    const row = await this.prisma.address.update({ where: { id }, data: patch });
    return this.toEntity(row);
  }

  async delete(id: string): Promise<void> {
    await this.prisma.address.delete({ where: { id } });
  }

  async clearDefault(userId: string): Promise<void> {
    await this.prisma.address.updateMany({
      where: { userId, isDefault: true },
      data: { isDefault: false },
    });
  }

  private toEntity(a: PrismaAddress): Address {
    return {
      id: a.id,
      userId: a.userId,
      label: a.label,
      text: a.text,
      lat: a.lat ?? undefined,
      lng: a.lng ?? undefined,
      isDefault: a.isDefault,
      createdAt: a.createdAt.toISOString(),
    };
  }
}
