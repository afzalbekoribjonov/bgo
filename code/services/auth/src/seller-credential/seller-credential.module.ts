import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { PrismaModule } from '../prisma/prisma.module';
import {
  AdminSellerCredentialController,
  SellerAuthController,
} from './seller-credential.controller';
import { SellerCredentialService } from './seller-credential.service';

/** Sotuvchi paneli (Do'konlar/Qurilish) login/parol kirishi. */
@Module({
  imports: [JwtModule.register({}), PrismaModule],
  controllers: [SellerAuthController, AdminSellerCredentialController],
  providers: [SellerCredentialService, JwtAuthGuard, RolesGuard],
})
export class SellerCredentialModule {}
