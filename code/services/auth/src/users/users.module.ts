import { Module } from '@nestjs/common';
import { PrismaUserRepository } from './prisma-user.repository';
import { UserRepository } from './user.repository';

/**
 * UserRepository abstraksiyasini implementatsiyaga bog'laydi.
 * Almashtirish uchun faqat shu provider o'zgaradi (qolgan kod tegmaydi).
 * Dev/test uchun in-memory variant ham bor: ./in-memory-user.repository.ts
 */
@Module({
  providers: [{ provide: UserRepository, useClass: PrismaUserRepository }],
  exports: [UserRepository],
})
export class UsersModule {}
