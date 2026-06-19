import { Logger, Module, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CatalogController } from './catalog.controller';
import { ManagementController } from './management.controller';
import { PrismaRestaurantRepository } from './prisma-restaurant.repository';
import { RestaurantRepository } from './restaurant.repository';
import { RestaurantsService } from './restaurants.service';

@Module({
  controllers: [CatalogController, ManagementController],
  providers: [
    RestaurantsService,
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
