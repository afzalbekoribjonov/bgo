import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { TariffService } from '../tariff/tariff.service';
import { ParcelController } from './parcel.controller';
import { ParcelDriverController } from './parcel-driver.controller';
import { ParcelRepository } from './parcel.repository';
import { ParcelService } from './parcel.service';
import { PrismaParcelRepository } from './prisma-parcel.repository';

/** Dostavka (pochta) vertikali moduli. plan/06-driver-app.md */
@Module({
  imports: [JwtModule.register({})],
  controllers: [ParcelController, ParcelDriverController],
  providers: [
    ParcelService,
    TariffService,
    JwtAuthGuard,
    RolesGuard,
    { provide: ParcelRepository, useClass: PrismaParcelRepository },
  ],
  exports: [ParcelService],
})
export class ParcelModule {}
