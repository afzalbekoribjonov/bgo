import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { UsersModule } from '../users/users.module';
import { AdminPartnersController } from './admin-partners.controller';
import { PartnerRepository } from './partner.repository';
import { PartnersController } from './partners.controller';
import { PartnersService } from './partners.service';
import { PrismaPartnerRepository } from './prisma-partner.repository';

/** Hamkorlik arizalari moduli. plan/08-admin-workspace.md */
@Module({
  imports: [UsersModule, JwtModule.register({})],
  controllers: [PartnersController, AdminPartnersController],
  providers: [
    PartnersService,
    JwtAuthGuard,
    RolesGuard,
    { provide: PartnerRepository, useClass: PrismaPartnerRepository },
  ],
})
export class PartnersModule {}
