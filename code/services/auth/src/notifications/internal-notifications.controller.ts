import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SendNotificationDto } from './dto/send-notification.dto';
import { InternalKeyGuard } from '@beshariq/nest-auth';
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
      android: dto.android,
    });
    return { success: true, data: result };
  }

  /** Dev introspeksiya — foydalanuvchiga yuborilgan oxirgi xabarlar (e2e). */
  @Get('recent')
  recent(@Query('userId') userId: string) {
    return { success: true, data: this.notifications.recentFor(userId ?? '') };
  }
}
