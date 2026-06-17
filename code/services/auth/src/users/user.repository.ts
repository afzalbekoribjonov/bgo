import { UserEntity } from './user.entity';

/**
 * Repository interfeysi (abstrakt) — saqlash texnologiyasidan mustaqil.
 * Hozir: InMemoryUserRepository (dev). Keyin: PrismaUserRepository (Postgres),
 * Docker o'rnatilganda — interfeys o'zgarmaydi. plan/03-databases.md
 */
export abstract class UserRepository {
  abstract findByPhone(phone: string): Promise<UserEntity | null>;
  abstract findById(id: string): Promise<UserEntity | null>;
  abstract create(data: { phone: string; locale?: string }): Promise<UserEntity>;
  abstract update(id: string, patch: Partial<UserEntity>): Promise<UserEntity>;
}
