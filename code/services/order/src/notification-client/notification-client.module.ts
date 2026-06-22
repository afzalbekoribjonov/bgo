import { Module } from '@nestjs/common';
import { NotificationClient } from './notification.client';

/** Push (auth servisi internal) klienti — order vertikallari ulashadi. */
@Module({
  providers: [NotificationClient],
  exports: [NotificationClient],
})
export class NotificationClientModule {}
