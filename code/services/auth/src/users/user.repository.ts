import { UserEntity } from './user.entity';

/**
 * Repository interfeysi (abstrakt) — saqlash texnologiyasidan mustaqil.
 * Implementatsiya: PrismaUserRepository (PostgreSQL auth_db). plan/03-databases.md
 */
export abstract class UserRepository {
  abstract findByPhone(phone: string): Promise<UserEntity | null>;
  abstract findById(id: string): Promise<UserEntity | null>;
  /** Bir nechta ID bo'yicha bitta so'rovda (admin ro'yxatlarni boyitish — N+1 o'rniga). */
  abstract findByIds(ids: string[]): Promise<UserEntity[]>;
  abstract findAll(): Promise<UserEntity[]>;
  abstract create(data: { phone: string; locale?: string }): Promise<UserEntity>;
  abstract update(id: string, patch: Partial<UserEntity>): Promise<UserEntity>;
  abstract block(id: string, reason: string): Promise<UserEntity>;
  abstract unblock(id: string): Promise<UserEntity>;
  abstract markMessagesRead(id: string): Promise<void>;
}
