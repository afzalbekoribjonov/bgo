import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { INTERNAL_KEY_HEADER, matchesInternalKey } from '@beshariq/nest-auth';
import {
  buildCorsOptions,
  resolveCorsOrigins,
  VALIDATION_PIPE_OPTIONS,
} from '@beshariq/nest-bootstrap';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Xavfsizlik sarlavhalari
  app.use(helmet());

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
    'http://localhost:3000',
    'http://localhost:3100',
  ]);
  app.enableCors(buildCorsOptions(corsOrigins));

  const port = process.env.ORDER_PORT ?? 4004;
  await app.listen(port);

  Logger.log(`🧾 Order servisi: http://localhost:${port}/api/v1`, 'Bootstrap');
  Logger.log(`🛡  Xavfsizlik: helmet + rate-limit (150/min)`, 'Bootstrap');
}

void bootstrap();
