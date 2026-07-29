import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { InternalKeyGuard } from '../notifications/internal-key.guard';
import { InternalUsersController } from './internal-users.controller';
import { PrismaUserRepository } from './prisma-user.repository';
import { UserRepository } from './user.repository';

/**
 * UserRepository abstraksiyasini implementatsiyaga bog'laydi.
 * Almashtirish uchun faqat shu provider o'zgaradi (qolgan kod tegmaydi).
 * Dev/test uchun in-memory variant ham bor: ./in-memory-user.repository.ts
 */
@Module({
  imports: [NotificationsModule],
  controllers: [InternalUsersController],
  providers: [
    { provide: UserRepository, useClass: PrismaUserRepository },
    InternalKeyGuard,
  ],
  exports: [UserRepository],
})
export class UsersModule {}
