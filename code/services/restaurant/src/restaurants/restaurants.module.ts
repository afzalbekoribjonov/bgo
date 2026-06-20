import { Logger, Module, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { CatalogController } from './catalog.controller';
import { ManagementController } from './management.controller';
import { PrismaRestaurantRepository } from './prisma-restaurant.repository';
import { RestaurantRepository } from './restaurant.repository';
import { RestaurantsService } from './restaurants.service';

@Module({
  imports: [JwtModule.register({})],
  controllers: [CatalogController, ManagementController],
  providers: [
    RestaurantsService,
    JwtAuthGuard,
    RolesGuard,
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
