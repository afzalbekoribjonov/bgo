import { Injectable } from '@nestjs/common';
import { DeviceToken as PrismaDeviceToken } from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import { DeviceTokenRepository } from './device-token.repository';
import { DevicePlatform, DeviceToken } from './notification.types';

/** PostgreSQL (auth_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaDeviceTokenRepository extends DeviceTokenRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async upsert(
    userId: string,
    token: string,
    platform: DevicePlatform,
  ): Promise<DeviceToken> {
    const row = await this.prisma.deviceToken.upsert({
      where: { token },
      create: { userId, token, platform },
      update: { userId, platform },
    });
    return this.toEntity(row);
  }

  async findByUser(userId: string): Promise<DeviceToken[]> {
    const rows = await this.prisma.deviceToken.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.toEntity(r));
  }

  async deleteByToken(userId: string, token: string): Promise<void> {
    await this.prisma.deviceToken.deleteMany({ where: { userId, token } });
  }

  async removeToken(token: string): Promise<void> {
    await this.prisma.deviceToken.deleteMany({ where: { token } });
  }

  private toEntity(d: PrismaDeviceToken): DeviceToken {
    return {
      id: d.id,
      userId: d.userId,
      token: d.token,
      platform: d.platform as DevicePlatform,
      createdAt: d.createdAt.toISOString(),
    };
  }
}
