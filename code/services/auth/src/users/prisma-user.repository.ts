import { Injectable } from '@nestjs/common';
import { Prisma, User as PrismaUser } from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import { UserEntity } from './user.entity';
import { UserRepository } from './user.repository';

/** PostgreSQL (auth_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaUserRepository extends UserRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async findByPhone(phone: string): Promise<UserEntity | null> {
    const user = await this.prisma.user.findUnique({ where: { phone } });
    return user ? this.toEntity(user) : null;
  }

  async findById(id: string): Promise<UserEntity | null> {
    const user = await this.prisma.user.findUnique({ where: { id } });
    return user ? this.toEntity(user) : null;
  }

  async findAll(): Promise<UserEntity[]> {
    const users = await this.prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return users.map((u) => this.toEntity(u));
  }

  async create(data: { phone: string; locale?: string }): Promise<UserEntity> {
    const user = await this.prisma.user.create({
      data: { phone: data.phone, locale: data.locale ?? 'uz' },
    });
    return this.toEntity(user);
  }

  async update(id: string, patch: Partial<UserEntity>): Promise<UserEntity> {
    const data: Prisma.UserUpdateInput = {};
    if (patch.fullName !== undefined) data.fullName = patch.fullName;
    if (patch.locale !== undefined) data.locale = patch.locale;
    if (patch.roles !== undefined) data.roles = { set: patch.roles };
    if (patch.consent !== undefined) {
      data.consentPrivacy = patch.consent.privacy;
      data.consentVersion = patch.consent.version;
      data.consentAcceptedAt = new Date(patch.consent.acceptedAt);
    }
    const user = await this.prisma.user.update({ where: { id }, data });
    return this.toEntity(user);
  }

  async block(id: string, reason: string): Promise<UserEntity> {
    const user = await this.prisma.user.update({
      where: { id },
      data: { isBlocked: true, blockedReason: reason, blockedAt: new Date() },
    });
    return this.toEntity(user);
  }

  async unblock(id: string): Promise<UserEntity> {
    const user = await this.prisma.user.update({
      where: { id },
      data: { isBlocked: false, blockedReason: null, blockedAt: null },
    });
    return this.toEntity(user);
  }

  async markMessagesRead(id: string): Promise<void> {
    await this.prisma.user.update({
      where: { id },
      data: { messagesReadAt: new Date() },
    });
  }

  private toEntity(u: PrismaUser): UserEntity {
    return {
      id: u.id,
      phone: u.phone,
      fullName: u.fullName ?? undefined,
      locale: u.locale,
      roles: u.roles,
      consent: u.consentPrivacy
        ? {
            privacy: u.consentPrivacy,
            version: u.consentVersion ?? '',
            acceptedAt: (u.consentAcceptedAt ?? new Date()).toISOString(),
          }
        : undefined,
      isBlocked: u.isBlocked,
      blockedReason: u.blockedReason,
      blockedAt: u.blockedAt?.toISOString() ?? null,
      messagesReadAt: u.messagesReadAt?.toISOString() ?? null,
      createdAt: u.createdAt.toISOString(),
    };
  }
}
