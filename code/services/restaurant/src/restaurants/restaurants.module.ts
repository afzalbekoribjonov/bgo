import { Logger, Module, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { InternalKeyGuard, JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { AuthClient } from '../auth-client/auth.client';
import { AdminRestaurantsController } from './admin-restaurants.controller';
import { CatalogController } from './catalog.controller';
import { InternalRestaurantsController } from './internal-restaurants.controller';
import { ManagementController } from './management.controller';
import { OwnerController } from './owner.controller';
import { PrismaRestaurantRepository } from './prisma-restaurant.repository';
import { RestaurantOwnerGuard } from './restaurant-owner.guard';
import { RestaurantRepository } from './restaurant.repository';
import { RestaurantsService } from './restaurants.service';
import { UploadController } from './upload.controller';

@Module({
  imports: [JwtModule.register({})],
  controllers: [
    CatalogController,
    AdminRestaurantsController,
    ManagementController,
    OwnerController,
    InternalRestaurantsController,
    UploadController,
  ],
  providers: [
    RestaurantsService,
    JwtAuthGuard,
    RolesGuard,
    InternalKeyGuard,
    RestaurantOwnerGuard,
    AuthClient,
    { provide: RestaurantRepository, useClass: PrismaRestaurantRepository },
  ],
  exports: [RestaurantsService],
})
export class RestaurantsModule implements OnModuleInit {
  private readonly logger = new Logger(RestaurantsModule.name);

  constructor(
    private readonly repo: RestaurantRepository,
    private readonly config: ConfigService,
  ) {}

  async onModuleInit(): Promise<void> {
    const seedOn = String(this.config.get('SEED_ON_START') ?? 'true') === 'true';
    if (seedOn && this.repo instanceof PrismaRestaurantRepository) {
      await this.repo.seedSampleData();
      this.logger.log('Namunaviy katalog tekshirildi (bo\'sh bo\'lsa yuklandi)');
    }
  }
}
