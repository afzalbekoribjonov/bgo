import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { InternalKeyGuard, JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { PrismaModule } from '../prisma/prisma.module';
import {
  AdminKitchenCredentialController,
  InternalKitchenCredentialController,
  KitchenAuthController,
} from './kitchen-credential.controller';
import { KitchenCredentialService } from './kitchen-credential.service';

/** Oshxona paneli login/parol kirishi (sayt + admin boshqaruvi). */
@Module({
  imports: [JwtModule.register({}), PrismaModule],
  controllers: [
    KitchenAuthController,
    AdminKitchenCredentialController,
    InternalKitchenCredentialController,
  ],
  providers: [KitchenCredentialService, JwtAuthGuard, RolesGuard, InternalKeyGuard],
})
export class KitchenCredentialModule {}
