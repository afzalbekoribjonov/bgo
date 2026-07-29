import { Injectable } from '@nestjs/common';
import {
  DriverProfile as PrismaDriver,
  Prisma,
} from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  DriverMessageEntity,
  DriverProfileEntity,
  DriverProfilePatch,
  DriverTopupEntity,
  NewDriverMessage,
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

  async findByUserId(userId: string): Promise<DriverProfileEntity | null> {
    const row = await this.prisma.driverProfile.findUnique({ where: { userId } });
    return row ? this.toEntity(row) : null;
  }

  async findByUserIds(userIds: string[]): Promise<DriverProfileEntity[]> {
    if (userIds.length === 0) return [];
    const rows = await this.prisma.driverProfile.findMany({
      where: { userId: { in: userIds } },
    });
    return rows.map((r) => this.toEntity(r));
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
    if (patch.isComfort !== undefined) data.isComfort = patch.isComfort;
    if (patch.rating !== undefined) data.rating = patch.rating;
    if (patch.blockedUntil !== undefined) data.blockedUntil = patch.blockedUntil;
    if (patch.blockReason !== undefined) data.blockReason = patch.blockReason;
    if (patch.consecutiveCancellations !== undefined) {
      data.consecutiveCancellations = patch.consecutiveCancellations;
    }
    const row = await this.prisma.driverProfile.update({ where: { id }, data });
    return this.toEntity(row);
  }

  async delete(id: string): Promise<void> {
    await this.prisma.driverProfile.delete({ where: { id } });
  }

  async topup(
    driverId: string,
    amount: number,
    note?: string,
    visible = true,
  ): Promise<DriverProfileEntity> {
    const [, profile] = await this.prisma.$transaction([
      this.prisma.driverTopup.create({
        data: { driverId, amount, note: note ?? null, visible },
      }),
      this.prisma.driverProfile.update({
        where: { id: driverId },
        data: { balance: { increment: amount } },
      }),
    ]);
    return this.toEntity(profile);
  }

  async listTopups(driverId: string): Promise<DriverTopupEntity[]> {
    const rows = await this.prisma.driverTopup.findMany({
      where: { driverId, visible: true },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => ({
      id: r.id,
      driverId: r.driverId,
      amount: r.amount,
      note: r.note,
      createdAt: r.createdAt.toISOString(),
    }));
  }

  // ---------- Xabarlar (admin → haydovchi) ----------

  async createMessage(data: NewDriverMessage): Promise<DriverMessageEntity> {
    const row = await this.prisma.driverMessage.create({
      data: {
        driverUserId: data.driverUserId ?? null,
        title: data.title ?? null,
        body: data.body,
      },
    });
    return this.toMessage(row);
  }

  async listMessagesFor(
    driverUserId: string,
    limit: number,
  ): Promise<DriverMessageEntity[]> {
    const rows = await this.prisma.driverMessage.findMany({
      where: { OR: [{ driverUserId: null }, { driverUserId }] },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    return rows.map((r) => this.toMessage(r));
  }

  async listAllMessages(limit: number): Promise<DriverMessageEntity[]> {
    const rows = await this.prisma.driverMessage.findMany({
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    return rows.map((r) => this.toMessage(r));
  }

  async countMessagesSince(
    driverUserId: string,
    since: Date | null,
  ): Promise<number> {
    return this.prisma.driverMessage.count({
      where: {
        OR: [{ driverUserId: null }, { driverUserId }],
        ...(since ? { createdAt: { gt: since } } : {}),
      },
    });
  }

  async markMessagesRead(profileId: string): Promise<void> {
    await this.prisma.driverProfile.update({
      where: { id: profileId },
      data: { messagesReadAt: new Date() },
    });
  }

  private toMessage(m: {
    id: string;
    driverUserId: string | null;
    title: string | null;
    body: string;
    createdAt: Date;
  }): DriverMessageEntity {
    return {
      id: m.id,
      driverUserId: m.driverUserId,
      title: m.title,
      body: m.body,
      createdAt: m.createdAt.toISOString(),
    };
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
      isComfort: d.isComfort,
      balance: d.balance,
      rating: d.rating,
      messagesReadAt: d.messagesReadAt?.toISOString() ?? null,
      blockedUntil: d.blockedUntil?.toISOString() ?? null,
      blockReason: d.blockReason,
      consecutiveCancellations: d.consecutiveCancellations,
      createdAt: d.createdAt.toISOString(),
      updatedAt: d.updatedAt.toISOString(),
    };
  }
}
