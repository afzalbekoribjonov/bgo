import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
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
    HealthModule,
  ],
})
export class AppModule {}
