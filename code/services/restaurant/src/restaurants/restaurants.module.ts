import { Logger, Module, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CatalogController } from './catalog.controller';
import { InMemoryRestaurantRepository } from './in-memory-restaurant.repository';
import { ManagementController } from './management.controller';
import { RestaurantRepository } from './restaurant.repository';
import { RestaurantsService } from './restaurants.service';

@Module({
  controllers: [CatalogController, ManagementController],
  providers: [
    RestaurantsService,
    { provide: RestaurantRepository, useClass: InMemoryRestaurantRepository },
  ],
  exports: [RestaurantsService],
})
export class RestaurantsModule implements OnModuleInit {
  private readonly logger = new Logger(RestaurantsModule.name);

  constructor(
    private readonly repo: RestaurantRepository,
    private readonly config: ConfigService,
  ) {}

  onModuleInit(): void {
    const seedOn = String(this.config.get('SEED_ON_START') ?? 'true') === 'true';
    if (seedOn && this.repo instanceof InMemoryRestaurantRepository) {
      this.repo.seedSampleData();
      this.logger.log('Namunaviy katalog yuklandi (dev seed)');
    }
  }
}
