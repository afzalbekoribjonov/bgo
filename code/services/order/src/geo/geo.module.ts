import { Logger, Module, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { AdminGeoController } from './admin-geo.controller';
import { GeoController } from './geo.controller';
import { GeoRepository } from './geo.repository';
import { GeoService } from './geo.service';
import { PrismaGeoRepository } from './prisma-geo.repository';

/** Xizmat hududlari + joylar moduli. plan/12-maps-navigation.md */
@Module({
  imports: [JwtModule.register({})],
  controllers: [GeoController, AdminGeoController],
  providers: [
    GeoService,
    JwtAuthGuard,
    RolesGuard,
    { provide: GeoRepository, useClass: PrismaGeoRepository },
  ],
  exports: [GeoService],
})
export class GeoModule implements OnModuleInit {
  private readonly logger = new Logger(GeoModule.name);

  constructor(
    private readonly geo: GeoService,
    private readonly config: ConfigService,
  ) {}

  async onModuleInit(): Promise<void> {
    const seedOn = String(this.config.get('SEED_ON_START') ?? 'true') === 'true';
    if (seedOn) {
      await this.geo.seedIfEmpty();
      await this.geo.seedRoadsIfEmpty();
    }
  }
}
