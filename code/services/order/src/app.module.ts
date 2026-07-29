import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { GeoModule } from './geo/geo.module';
import { HealthModule } from './health/health.module';
import { OrdersModule } from './orders/orders.module';
import { ParcelModule } from './parcel/parcel.module';
import { PrismaModule } from './prisma/prisma.module';
import { StoreOrdersModule } from './store-orders/store-orders.module';
import { TaxiModule } from './taxi/taxi.module';
import { TrackingModule } from './tracking/tracking.module';

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
    StoreOrdersModule,
    GeoModule,
    TrackingModule,
    HealthModule,
  ],
})
export class AppModule {}
