import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { SendNotificationDto } from './dto/send-notification.dto';
import { InternalKeyGuard } from './internal-key.guard';
import { NotificationService } from './notification.service';

/**
 * Servislararo push yuborish (order/restaurant servislari chaqiradi).
 * `x-internal-key` bilan himoyalangan; gateway proxy qilmaydi (faqat internal).
 */
@Controller('internal/notifications')
@UseGuards(InternalKeyGuard)
export class InternalNotificationsController {
  constructor(private readonly notifications: NotificationService) {}

  @Post('send')
  @HttpCode(200)
  async send(@Body() dto: SendNotificationDto) {
    const result = await this.notifications.notifyUser(dto.userId, {
      title: dto.title,
      body: dto.body,
      data: dto.data,
    });
    return { success: true, data: result };
  }
}
