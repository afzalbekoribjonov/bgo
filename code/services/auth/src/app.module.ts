import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { CustomersModule } from './customers/customers.module';
import { DriversModule } from './drivers/drivers.module';
import { HealthModule } from './health/health.module';
import { KitchenCredentialModule } from './kitchen-credential/kitchen-credential.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PartnersModule } from './partners/partners.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProfileModule } from './profile/profile.module';
import { SellerCredentialModule } from './seller-credential/seller-credential.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '../../.env'],
    }),
    PrismaModule,
    UsersModule,
    AuthModule,
    CustomersModule,
    DriversModule,
    PartnersModule,
    ProfileModule,
    NotificationsModule,
    KitchenCredentialModule,
    SellerCredentialModule,
    HealthModule,
  ],
})
export class AppModule {}
