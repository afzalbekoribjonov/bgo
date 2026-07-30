import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { INTERNAL_KEY_HEADER, matchesInternalKey } from '@beshariq/nest-auth';
import {
  buildCorsOptions,
  resolveCorsOrigins,
  VALIDATION_PIPE_OPTIONS,
} from '@beshariq/nest-bootstrap';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { AppModule } from './app.module';
import { UPLOADS_DIR } from './market/upload.controller';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Yuklangan rasmlar (lokal rejim) — gateway orqali ochiq ko'rsatiladi
  app.useStaticAssets(UPLOADS_DIR, {
    prefix: '/api/v1/market/uploads/',
    maxAge: '30d',
    immutable: true,
  });

  // Xavfsizlik sarlavhalari (CORP cross-origin — rasmlar boshqa portdagi
  // saytlarda <img> orqali ko'rsatiladi)
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

  // DDoS himoyasi: umumiy limit (ichki servis so'rovlari limitlanmaydi)
  app.use(
    rateLimit({
      windowMs: 60 * 1000,
      max: 150,
      standardHeaders: true,
      legacyHeaders: false,
      message: { message: "Juda ko'p so'rov yuborildi. Bir daqiqa kutib ko'ring." },
      skip: (req) => matchesInternalKey(req.headers[INTERNAL_KEY_HEADER]),
    }),
  );

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(new ValidationPipe(VALIDATION_PIPE_OPTIONS));

  const corsOrigins = resolveCorsOrigins([
    'http://localhost:4000',
    'http://localhost:3200',
    'http://localhost:3300',
  ]);
  app.enableCors(buildCorsOptions(corsOrigins));

  const port = process.env.MARKET_PORT ?? 4005;
  await app.listen(port);

  Logger.log(`🛒 Market servisi: http://localhost:${port}/api/v1`, 'Bootstrap');
  Logger.log(`🛡  Xavfsizlik: helmet + rate-limit (150/min)`, 'Bootstrap');
}

void bootstrap();
