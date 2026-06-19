import { UserEntity } from './user.entity';

/**
 * Repository interfeysi (abstrakt) — saqlash texnologiyasidan mustaqil.
 * Implementatsiya: PrismaUserRepository (PostgreSQL auth_db). plan/03-databases.md
 */
export abstract class UserRepository {
  abstract findByPhone(phone: string): Promise<UserEntity | null>;
  abstract findById(id: string): Promise<UserEntity | null>;
  abstract findAll(): Promise<UserEntity[]>;
  abstract create(data: { phone: string; locale?: string }): Promise<UserEntity>;
  abstract update(id: string, patch: Partial<UserEntity>): Promise<UserEntity>;
}
