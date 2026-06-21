import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TelegramLink, TelegramRepository } from './telegram.repository';

/** PostgreSQL (auth_db) implementatsiyasi. */
@Injectable()
export class PrismaTelegramRepository extends TelegramRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async findByPhone(phone: string): Promise<TelegramLink | null> {
    const row = await this.prisma.telegramLink.findUnique({ where: { phone } });
    return row
      ? { phone: row.phone, chatId: row.chatId, username: row.username ?? undefined }
      : null;
  }

  async upsert(data: TelegramLink): Promise<TelegramLink> {
    const row = await this.prisma.telegramLink.upsert({
      where: { phone: data.phone },
      update: { chatId: data.chatId, username: data.username },
      create: { phone: data.phone, chatId: data.chatId, username: data.username },
    });
    return { phone: row.phone, chatId: row.chatId, username: row.username ?? undefined };
  }
}
