import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RestaurantClient } from '../restaurant-client/restaurant.client';
import { InMemoryOrderRepository } from './in-memory-order.repository';
import { OrderRepository } from './order.repository';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

@Module({
  imports: [JwtModule.register({})],
  controllers: [OrdersController],
  providers: [
    OrdersService,
    RestaurantClient,
    JwtAuthGuard,
    { provide: OrderRepository, useClass: InMemoryOrderRepository },
  ],
})
export class OrdersModule {}
