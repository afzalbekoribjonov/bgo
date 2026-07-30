import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { InternalKeyGuard, JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { NotificationClientModule } from '../notification-client/notification-client.module';
import { ParcelModule } from '../parcel/parcel.module';
import { DriverInfoClient } from '../driver-client/driver-info.client';
import { RestaurantClient } from '../restaurant-client/restaurant.client';
import { TaxiModule } from '../taxi/taxi.module';
import { AdminController } from './admin.controller';
import { InternalTariffController } from '../tariff/internal-tariff.controller';
import { CourierController } from './courier.controller';
import { InternalOrderLookupController } from './internal-order-lookup.controller';
import { DispatchModule } from './dispatch.module';
import { TrackingModule } from '../tracking/tracking.module';
import { KitchenController } from './kitchen.controller';
import { OrderMessageRepository } from './order-message.repository';
import { OrderRepository } from './order.repository';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { PrismaOrderMessageRepository } from './prisma-order-message.repository';
import { PrismaOrderRepository } from './prisma-order.repository';
import { TariffService } from '../tariff/tariff.service';
import { PromoService } from '../promo/promo.service';

@Module({
  imports: [
    JwtModule.register({}),
    TaxiModule,
    ParcelModule,
    NotificationClientModule,
    DispatchModule,
    TrackingModule,
  ],
  controllers: [
    OrdersController,
    KitchenController,
    CourierController,
    AdminController,
    InternalTariffController,
    InternalOrderLookupController,
  ],
  providers: [
    OrdersService,
    RestaurantClient,
    DriverInfoClient,
    TariffService,
    PromoService,
    JwtAuthGuard,
    RolesGuard,
    InternalKeyGuard,
    { provide: OrderRepository, useClass: PrismaOrderRepository },
    {
      provide: OrderMessageRepository,
      useClass: PrismaOrderMessageRepository,
    },
  ],
})
export class OrdersModule {}
