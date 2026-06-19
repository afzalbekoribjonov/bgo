import { Injectable } from '@nestjs/common';
import { Prisma, User as PrismaUser } from '@prisma/client';
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
      createdAt: u.createdAt.toISOString(),
    };
  }
}
