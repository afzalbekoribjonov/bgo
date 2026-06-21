import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UsersModule } from '../users/users.module';
import { AddressRepository } from './address.repository';
import { PrismaAddressRepository } from './prisma-address.repository';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';

/** Profil + manzillar moduli. plan/05-customer-app.md */
@Module({
  imports: [UsersModule, JwtModule.register({})],
  controllers: [ProfileController],
  providers: [
    ProfileService,
    JwtAuthGuard,
    { provide: AddressRepository, useClass: PrismaAddressRepository },
  ],
})
export class ProfileModule {}
