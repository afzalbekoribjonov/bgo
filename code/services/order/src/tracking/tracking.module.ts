import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { DriverLocationRepository } from './driver-location.repository';
import { DriverLocationService } from './driver-location.service';
import { PrismaDriverLocationRepository } from './prisma-driver-location.repository';
import { TrackingController } from './tracking.controller';
import { TripDistanceTracker } from './trip-distance-tracker.service';

/** Haydovchi jonli joylashuvi moduli. plan/12-maps-navigation.md */
@Module({
  imports: [JwtModule.register({})],
  controllers: [TrackingController],
  providers: [
    DriverLocationService,
    TripDistanceTracker,
    JwtAuthGuard,
    RolesGuard,
    {
      provide: DriverLocationRepository,
      useClass: PrismaDriverLocationRepository,
    },
  ],
  exports: [DriverLocationService],
})
export class TrackingModule {}
