import { Module } from '@nestjs/common';
import { DeviceTokenRepository } from './device-token.repository';
import { InternalNotificationsController } from './internal-notifications.controller';
import { InternalKeyGuard } from '@beshariq/nest-auth';
import { NotificationService } from './notification.service';
import { PrismaDeviceTokenRepository } from './prisma-device-token.repository';

/** Push bildirishnomalar moduli (FCM + qurilma tokenlari). plan/10-auth-security.md */
@Module({
  controllers: [InternalNotificationsController],
  providers: [
    NotificationService,
    InternalKeyGuard,
    { provide: DeviceTokenRepository, useClass: PrismaDeviceTokenRepository },
  ],
  exports: [NotificationService],
})
export class NotificationsModule {}
