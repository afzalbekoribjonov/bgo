import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { TariffService } from '../tariff/tariff.service';
import { PrismaTaxiRepository } from './prisma-taxi.repository';
import { TaxiController } from './taxi.controller';
import { TaxiDriverController } from './taxi-driver.controller';
import { TaxiRepository } from './taxi.repository';
import { TaxiService } from './taxi.service';

/** Taksi vertikali moduli. plan/06-driver-app.md */
@Module({
  imports: [JwtModule.register({})],
  controllers: [TaxiController, TaxiDriverController],
  providers: [
    TaxiService,
    TariffService,
    JwtAuthGuard,
    RolesGuard,
    { provide: TaxiRepository, useClass: PrismaTaxiRepository },
  ],
  exports: [TaxiService],
})
export class TaxiModule {}
