import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { UserEntity } from './user.entity';
import { UserRepository } from './user.repository';

/**
 * Xotirada saqlovchi repository — FAQAT dev/test uchun.
 * Server qayta ishga tushsa ma'lumot yo'qoladi.
 * TODO(Faza 1B + Docker): PrismaUserRepository (PostgreSQL auth_db) bilan almashtirish.
 */
@Injectable()
export class InMemoryUserRepository extends UserRepository {
  private readonly byId = new Map<string, UserEntity>();

  async findByPhone(phone: string): Promise<UserEntity | null> {
    for (const user of this.byId.values()) {
      if (user.phone === phone) return { ...user };
    }
    return null;
  }

  async findById(id: string): Promise<UserEntity | null> {
    const user = this.byId.get(id);
    return user ? { ...user } : null;
  }

  async create(data: { phone: string; locale?: string }): Promise<UserEntity> {
    const user: UserEntity = {
      id: randomUUID(),
      phone: data.phone,
      locale: data.locale ?? 'uz',
      roles: ['customer'],
      createdAt: new Date().toISOString(),
    };
    this.byId.set(user.id, user);
    return { ...user };
  }

  async update(id: string, patch: Partial<UserEntity>): Promise<UserEntity> {
    const existing = this.byId.get(id);
    if (!existing) throw new NotFoundException('Foydalanuvchi topilmadi');
    const updated = { ...existing, ...patch, id: existing.id };
    this.byId.set(id, updated);
    return { ...updated };
  }
}
