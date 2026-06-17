import { Module } from '@nestjs/common';
import { InMemoryUserRepository } from './in-memory-user.repository';
import { UserRepository } from './user.repository';

/**
 * UserRepository abstraksiyasini implementatsiyaga bog'laydi.
 * Almashtirish uchun faqat shu provider o'zgaradi (qolgan kod tegmaydi).
 */
@Module({
  providers: [{ provide: UserRepository, useClass: InMemoryUserRepository }],
  exports: [UserRepository],
})
export class UsersModule {}
