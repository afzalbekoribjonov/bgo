import { Module } from '@nestjs/common';
import { TrackingModule } from '../tracking/tracking.module';
import { DispatchService } from './dispatch.service';

/**
 * Buyurtma dispatch (taklif) dvigateli — bitta umumiy instans (in-memory).
 * Ovqat/taksi/dostavka modullari shu DispatchService'ni ulashadi.
 */
@Module({
  imports: [TrackingModule],
  providers: [DispatchService],
  exports: [DispatchService],
})
export class DispatchModule {}
