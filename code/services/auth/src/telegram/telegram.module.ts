import { Module } from '@nestjs/common';
import { PrismaTelegramRepository } from './prisma-telegram.repository';
import { TelegramController } from './telegram.controller';
import { TelegramRepository } from './telegram.repository';
import { TelegramService } from './telegram.service';

/** Telegram OTP kanali moduli. plan/10-auth-security.md */
@Module({
  controllers: [TelegramController],
  providers: [
    TelegramService,
    { provide: TelegramRepository, useClass: PrismaTelegramRepository },
  ],
  exports: [TelegramService],
})
export class TelegramModule {}
