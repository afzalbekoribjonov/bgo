import { Injectable } from '@nestjs/common';
import {
  DriverProfile as PrismaDriver,
  Prisma,
} from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  DriverProfileEntity,
  DriverProfilePatch,
  NewDriverProfile,
} from './driver.entity';
import { DriverRepository } from './driver.repository';

/** PostgreSQL (auth_db) implementatsiyasi. */
@Injectable()
export class PrismaDriverRepository extends DriverRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async findAll(): Promise<DriverProfileEntity[]> {
    const rows = await this.prisma.driverProfile.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.toEntity(r));
  }

  async findById(id: string): Promise<DriverProfileEntity | null> {
    const row = await this.prisma.driverProfile.findUnique({ where: { id } });
    return row ? this.toEntity(row) : null;
  }

  async findByPhone(phone: string): Promise<DriverProfileEntity | null> {
    const row = await this.prisma.driverProfile.findUnique({ where: { phone } });
    return row ? this.toEntity(row) : null;
  }

  async create(data: NewDriverProfile): Promise<DriverProfileEntity> {
    const row = await this.prisma.driverProfile.create({
      data: {
        userId: data.userId,
        phone: data.phone,
        fullName: data.fullName,
        age: data.age ?? null,
        carName: data.carName ?? null,
        carYear: data.carYear ?? null,
        plateNumber: data.plateNumber ?? null,
        licenseInfo: data.licenseInfo ?? null,
        loginCode: data.loginCode,
      },
    });
    return this.toEntity(row);
  }

  async update(
    id: string,
    patch: DriverProfilePatch,
  ): Promise<DriverProfileEntity> {
    const data: Prisma.DriverProfileUpdateInput = {};
    if (patch.fullName !== undefined) data.fullName = patch.fullName;
    if (patch.age !== undefined) data.age = patch.age;
    if (patch.carName !== undefined) data.carName = patch.carName;
    if (patch.carYear !== undefined) data.carYear = patch.carYear;
    if (patch.plateNumber !== undefined) data.plateNumber = patch.plateNumber;
    if (patch.licenseInfo !== undefined) data.licenseInfo = patch.licenseInfo;
    if (patch.loginCode !== undefined) data.loginCode = patch.loginCode;
    if (patch.isActive !== undefined) data.isActive = patch.isActive;
    if (patch.isOnline !== undefined) data.isOnline = patch.isOnline;
    const row = await this.prisma.driverProfile.update({ where: { id }, data });
    return this.toEntity(row);
  }

  async delete(id: string): Promise<void> {
    await this.prisma.driverProfile.delete({ where: { id } });
  }

  private toEntity(d: PrismaDriver): DriverProfileEntity {
    return {
      id: d.id,
      userId: d.userId,
      phone: d.phone,
      fullName: d.fullName,
      age: d.age,
      carName: d.carName,
      carYear: d.carYear,
      plateNumber: d.plateNumber,
      licenseInfo: d.licenseInfo,
      loginCode: d.loginCode,
      isActive: d.isActive,
      isOnline: d.isOnline,
      createdAt: d.createdAt.toISOString(),
      updatedAt: d.updatedAt.toISOString(),
    };
  }
}
