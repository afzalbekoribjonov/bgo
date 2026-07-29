import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Xavfsizlik sarlavhalari
  app.use(helmet());

  // DDoS himoyasi: umumiy limit
  app.use(
    rateLimit({
      windowMs: 60 * 1000,
      max: 150,
      standardHeaders: true,
      legacyHeaders: false,
      message: { message: "Juda ko'p so'rov yuborildi. Bir daqiqa kutib ko'ring." },
      skip: (req) => {
        // Ichki servis so'rovlari limitlanmaydi
        const key = req.headers['x-internal-key'] as string | undefined;
        return !!key && key === process.env.INTERNAL_API_KEY;
      },
    }),
  );

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const corsOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((o) => o.trim())
    : ['http://localhost:4000', 'http://localhost:3000', 'http://localhost:3100'];

  app.enableCors({
    origin: corsOrigins,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Internal-Key'],
    credentials: true,
  });

  const port = process.env.ORDER_PORT ?? 4004;
  await app.listen(port);

  Logger.log(`🧾 Order servisi: http://localhost:${port}/api/v1`, 'Bootstrap');
  Logger.log(`🛡  Xavfsizlik: helmet + rate-limit (150/min)`, 'Bootstrap');
}

void bootstrap();
