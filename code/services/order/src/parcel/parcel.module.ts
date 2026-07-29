import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { NotificationClientModule } from '../notification-client/notification-client.module';
import { DriverInfoClient } from '../driver-client/driver-info.client';
import { DispatchModule } from '../orders/dispatch.module';
import { TariffService } from '../tariff/tariff.service';
import { TrackingModule } from '../tracking/tracking.module';
import { ParcelController } from './parcel.controller';
import { ParcelDriverController } from './parcel-driver.controller';
import { ParcelMessageRepository } from './parcel-message.repository';
import { ParcelRepository } from './parcel.repository';
import { ParcelService } from './parcel.service';
import { PrismaParcelMessageRepository } from './prisma-parcel-message.repository';
import { PrismaParcelRepository } from './prisma-parcel.repository';

/** Dostavka (pochta) vertikali moduli. plan/06-driver-app.md */
@Module({
  imports: [
    JwtModule.register({}),
    NotificationClientModule,
    DispatchModule,
    TrackingModule,
  ],
  controllers: [ParcelController, ParcelDriverController],
  providers: [
    ParcelService,
    TariffService,
    DriverInfoClient,
    JwtAuthGuard,
    RolesGuard,
    { provide: ParcelRepository, useClass: PrismaParcelRepository },
    {
      provide: ParcelMessageRepository,
      useClass: PrismaParcelMessageRepository,
    },
  ],
  exports: [ParcelService],
})
export class ParcelModule {}
