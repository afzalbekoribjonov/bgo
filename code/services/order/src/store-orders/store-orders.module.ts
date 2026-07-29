import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { DispatchModule } from '../orders/dispatch.module';
import { DriverInfoClient } from '../driver-client/driver-info.client';
import { MarketClient } from '../market-client/market.client';
import { NotificationClientModule } from '../notification-client/notification-client.module';
import { TariffService } from '../tariff/tariff.service';
import { TrackingModule } from '../tracking/tracking.module';
import { PrismaStoreOrderRepository } from './prisma-store-order.repository';
import { StoreOrderRepository } from './store-order.repository';
import { StoreOrdersAdminController } from './store-orders-admin.controller';
import { StoreOrdersDriverController } from './store-orders-driver.controller';
import { StoreOrdersController } from './store-orders.controller';
import { StoreOrdersService } from './store-orders.service';

/** Beshariq Market buyurtma + yetkazish/olib ketish moduli. */
@Module({
  imports: [JwtModule.register({}), NotificationClientModule, DispatchModule, TrackingModule],
  controllers: [StoreOrdersController, StoreOrdersDriverController, StoreOrdersAdminController],
  providers: [
    StoreOrdersService,
    TariffService,
    DriverInfoClient,
    MarketClient,
    JwtAuthGuard,
    RolesGuard,
    { provide: StoreOrderRepository, useClass: PrismaStoreOrderRepository },
  ],
  exports: [StoreOrdersService],
})
export class StoreOrdersModule {}
