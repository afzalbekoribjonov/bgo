import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { PrismaModule } from '../prisma/prisma.module';
import {
  AdminKitchenCredentialController,
  KitchenAuthController,
} from './kitchen-credential.controller';
import { KitchenCredentialService } from './kitchen-credential.service';

/** Oshxona paneli login/parol kirishi (sayt + admin boshqaruvi). */
@Module({
  imports: [JwtModule.register({}), PrismaModule],
  controllers: [KitchenAuthController, AdminKitchenCredentialController],
  providers: [KitchenCredentialService, JwtAuthGuard, RolesGuard],
})
export class KitchenCredentialModule {}
