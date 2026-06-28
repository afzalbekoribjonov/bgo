import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { NotificationClientModule } from '../notification-client/notification-client.module';
import { ParcelModule } from '../parcel/parcel.module';
import { RestaurantClient } from '../restaurant-client/restaurant.client';
import { TaxiModule } from '../taxi/taxi.module';
import { AdminController } from './admin.controller';
import { CourierController } from './courier.controller';
import { DispatchModule } from './dispatch.module';
import { KitchenController } from './kitchen.controller';
import { OrderRepository } from './order.repository';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
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
  ],
  controllers: [
    OrdersController,
    KitchenController,
    CourierController,
    AdminController,
  ],
  providers: [
    OrdersService,
    RestaurantClient,
    TariffService,
    PromoService,
    JwtAuthGuard,
    RolesGuard,
    { provide: OrderRepository, useClass: PrismaOrderRepository },
  ],
})
export class OrdersModule {}
