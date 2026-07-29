import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { AdminController } from './admin.controller';
import { CatalogController } from './catalog.controller';
import { ImageKitService } from './imagekit.service';
import { MarketplaceService } from './marketplace.service';
import { SellerController } from './seller.controller';
import { UploadController } from './upload.controller';

@Module({
  imports: [JwtModule.register({})],
  controllers: [
    CatalogController,
    SellerController,
    AdminController,
    UploadController,
  ],
  providers: [MarketplaceService, ImageKitService, JwtAuthGuard, RolesGuard],
  exports: [MarketplaceService],
})
export class MarketplaceModule {}
