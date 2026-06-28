import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { UsersModule } from '../users/users.module';
import { AdminDriversController } from './admin-drivers.controller';
import { DriverAuthController } from './driver-auth.controller';
import { DriverRepository } from './driver.repository';
import { DriversService } from './drivers.service';
import { PrismaDriverRepository } from './prisma-driver.repository';

/** Haydovchi onboarding + login (admin qo'shadi, 8 xonali kod). */
@Module({
  imports: [UsersModule, JwtModule.register({})],
  controllers: [AdminDriversController, DriverAuthController],
  providers: [
    DriversService,
    { provide: DriverRepository, useClass: PrismaDriverRepository },
    JwtAuthGuard,
    RolesGuard,
  ],
})
export class DriversModule {}
