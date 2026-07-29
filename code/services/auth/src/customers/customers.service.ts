import { Injectable, NotFoundException } from '@nestjs/common';
import { UserRepository } from '../users/user.repository';
import { NotificationService } from '../notifications/notification.service';
import { SendCustomerMessageDto } from './dto/customer.dto';
import { CustomerMessageRepository } from './customer-message.repository';

/**
 * Mijoz moderatsiyasi (bloklash) + admin → mijoz xabarlar. DriversService'ning
 * xabar bo'limi bilan bir xil naqsh, faqat DriverProfile o'rniga to'g'ridan-to'g'ri
 * User (mijoz uchun alohida profil jadvali yo'q).
 */
@Injectable()
export class CustomersService {
  constructor(
    private readonly users: UserRepository,
    private readonly repo: CustomerMessageRepository,
    private readonly notifications: NotificationService,
  ) {}

  // ---------- Bloklash ----------

  async getById(userId: string) {
    const user = await this.users.findById(userId);
    if (!user) throw new NotFoundException('Mijoz topilmadi');
    return user;
  }

  async block(userId: string, reason: string) {
    const user = await this.users.findById(userId);
    if (!user) throw new NotFoundException('Mijoz topilmadi');
    return this.users.block(userId, reason);
  }

  async unblock(userId: string) {
    const user = await this.users.findById(userId);
    if (!user) throw new NotFoundException('Mijoz topilmadi');
    return this.users.unblock(userId);
  }

  // ---------- Xabarlar (admin → mijoz) ----------

  /** Admin xabar yuboradi: customerId berilsa — bitta mijozga, bo'lmasa hammaga. */
  async sendMessage(dto: SendCustomerMessageDto) {
    if (dto.customerId) {
      const user = await this.users.findById(dto.customerId);
      if (!user) throw new NotFoundException('Mijoz topilmadi');
    }
    const msg = await this.repo.createMessage({
      customerId: dto.customerId ?? null,
      title: dto.title?.trim() || null,
      body: dto.body.trim(),
    });

    const push = {
      title: msg.title ?? 'Beshariq — yangi xabar',
      body: msg.body,
      data: { type: 'customer_message', messageId: msg.id },
    };
    if (dto.customerId) {
      this.notifications.notifyUser(dto.customerId, push).catch(() => undefined);
    }
    // Eslatma: broadcast (customerId yo'q) uchun barcha mijozlarga push yuborish
    // — foydalanuvchilar soni ko'p bo'lishi mumkin, hozircha faqat shaxsiy
    // xabarlarda darhol push yuboriladi; broadcast uchun kelajakda navbat
    // (queue) orqali amalga oshiriladi.
    return msg;
  }

  /** Admin: yuborilgan xabarlar tarixi (oxirgi 200). */
  async listSentMessages() {
    return this.repo.listAllMessages(200);
  }

  /** Mijoz: menga tegishli xabarlar (broadcast + shaxsiy, yangi birinchi). */
  async myMessages(userId: string) {
    const user = await this.users.findById(userId);
    if (!user) throw new NotFoundException('Foydalanuvchi topilmadi');
    const messages = await this.repo.listMessagesFor(userId, 100);
    return { messages, readAt: user.messagesReadAt ?? null };
  }

  /** Mijoz: o'qilmagan xabarlar soni (badge). */
  async unreadMessagesCount(userId: string): Promise<{ count: number }> {
    const user = await this.users.findById(userId);
    if (!user) return { count: 0 };
    const since = user.messagesReadAt ? new Date(user.messagesReadAt) : null;
    return { count: await this.repo.countMessagesSince(userId, since) };
  }

  /** Mijoz: xabarlar ekrani ochildi — hammasi o'qilgan deb belgila. */
  async markMessagesRead(userId: string) {
    await this.users.markMessagesRead(userId);
    return { ok: true };
  }
}
