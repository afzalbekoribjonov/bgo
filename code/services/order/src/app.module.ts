import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { GeoModule } from './geo/geo.module';
import { HealthModule } from './health/health.module';
import { OrdersModule } from './orders/orders.module';
import { ParcelModule } from './parcel/parcel.module';
import { PrismaModule } from './prisma/prisma.module';
import { TaxiModule } from './taxi/taxi.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '../../.env'],
    }),
    PrismaModule,
    OrdersModule,
    TaxiModule,
    ParcelModule,
    GeoModule,
    HealthModule,
  ],
})
export class AppModule {}
