import { Module } from '@nestjs/common';
import { DriverInfoClient } from '../driver-client/driver-info.client';
import { NotificationClientModule } from '../notification-client/notification-client.module';
import { TrackingModule } from '../tracking/tracking.module';
import { DispatchService } from './dispatch.service';

/**
 * Buyurtma dispatch (taklif) dvigateli — bitta umumiy instans (in-memory).
 * Ovqat/taksi/dostavka modullari shu DispatchService'ni ulashadi.
 */
@Module({
  imports: [TrackingModule, NotificationClientModule],
  providers: [DispatchService, DriverInfoClient],
  exports: [DispatchService],
})
export class DispatchModule {}
