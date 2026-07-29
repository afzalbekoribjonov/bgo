import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard, RolesGuard } from '@beshariq/nest-auth';
import { GeminiClient } from '../ai/gemini.client';
import { OrderLookupClient } from '../ai/order-lookup.client';
import { TariffKnowledgeClient } from '../ai/tariff-knowledge.client';
import { UserInfoClient } from '../user-client/user-info.client';
import { AdminController } from './admin.controller';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';

@Module({
  imports: [JwtModule.register({})],
  controllers: [SupportController, AdminController],
  providers: [
    SupportService,
    GeminiClient,
    TariffKnowledgeClient,
    OrderLookupClient,
    UserInfoClient,
    JwtAuthGuard,
    RolesGuard,
  ],
})
export class SupportModule {}
