import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AdminCustomersController } from './admin-customers.controller';
import { CustomerMessageRepository } from './customer-message.repository';
import { PrismaCustomerMessageRepository } from './prisma-customer-message.repository';
import { CustomersService } from './customers.service';

/** Mijoz moderatsiyasi (bloklash) + admin → mijoz xabarlar. */
@Module({
  imports: [UsersModule, NotificationsModule, JwtModule.register({})],
  controllers: [AdminCustomersController],
  providers: [
    CustomersService,
    { provide: CustomerMessageRepository, useClass: PrismaCustomerMessageRepository },
    JwtAuthGuard,
    RolesGuard,
  ],
  exports: [CustomersService],
})
export class CustomersModule {}
