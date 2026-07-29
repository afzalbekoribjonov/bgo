import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { NotificationClientModule } from '../notification-client/notification-client.module';
import { DriverInfoClient } from '../driver-client/driver-info.client';
import { DispatchModule } from '../orders/dispatch.module';
import { TariffService } from '../tariff/tariff.service';
import { TrackingModule } from '../tracking/tracking.module';
import { PrismaTaxiMessageRepository } from './prisma-taxi-message.repository';
import { PrismaTaxiRepository } from './prisma-taxi.repository';
import { TaxiController } from './taxi.controller';
import { TaxiDriverController } from './taxi-driver.controller';
import { TaxiMessageRepository } from './taxi-message.repository';
import { TaxiRepository } from './taxi.repository';
import { TaxiService } from './taxi.service';

/** Taksi vertikali moduli. plan/06-driver-app.md */
@Module({
  imports: [
    JwtModule.register({}),
    NotificationClientModule,
    TrackingModule,
    DispatchModule,
  ],
  controllers: [TaxiController, TaxiDriverController],
  providers: [
    TaxiService,
    TariffService,
    DriverInfoClient,
    JwtAuthGuard,
    RolesGuard,
    { provide: TaxiRepository, useClass: PrismaTaxiRepository },
    { provide: TaxiMessageRepository, useClass: PrismaTaxiMessageRepository },
  ],
  exports: [TaxiService],
})
export class TaxiModule {}
