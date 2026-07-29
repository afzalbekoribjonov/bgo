import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { UserInfoClient } from '../user-client/user-info.client';
import { AdminController } from './admin.controller';
import { CatalogController } from './catalog.controller';
import { ImageKitService } from './imagekit.service';
import { InternalController } from './internal.controller';
import { MarketService } from './market.service';
import { SupportController } from './support.controller';
import { UploadController } from './upload.controller';

@Module({
  imports: [JwtModule.register({})],
  controllers: [
    CatalogController,
    SupportController,
    AdminController,
    UploadController,
    InternalController,
  ],
  providers: [MarketService, ImageKitService, JwtAuthGuard, RolesGuard, UserInfoClient],
  exports: [MarketService],
})
export class MarketModule {}
