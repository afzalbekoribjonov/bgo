import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RestaurantClient } from '../restaurant-client/restaurant.client';
import { KitchenController } from './kitchen.controller';
import { OrderRepository } from './order.repository';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { PrismaOrderRepository } from './prisma-order.repository';

@Module({
  imports: [JwtModule.register({})],
  controllers: [OrdersController, KitchenController],
  providers: [
    OrdersService,
    RestaurantClient,
    JwtAuthGuard,
    { provide: OrderRepository, useClass: PrismaOrderRepository },
  ],
})
export class OrdersModule {}
