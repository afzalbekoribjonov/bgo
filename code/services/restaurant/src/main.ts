import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { AppModule } from './app.module';
import { UPLOADS_DIR } from './restaurants/upload.controller';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Yuklangan taom rasmlari — gateway orqali ochiq ko'rsatiladi
  app.useStaticAssets(UPLOADS_DIR, {
    prefix: '/api/v1/restaurants/uploads/',
    maxAge: '30d',
    immutable: true,
  });

  // Xavfsizlik sarlavhalari (CORP cross-origin — rasmlar boshqa portdagi
  // saytlarda <img> orqali ko'rsatiladi)
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

  // DDoS himoyasi: umumiy limit
  app.use(
    rateLimit({
      windowMs: 60 * 1000,
      max: 150,
      standardHeaders: true,
      legacyHeaders: false,
      message: { message: "Juda ko'p so'rov yuborildi. Bir daqiqa kutib ko'ring." },
      skip: (req) => {
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

  const port = process.env.RESTAURANT_PORT ?? 3003;
  await app.listen(port);

  Logger.log(`🍽  Restaurant servisi: http://localhost:${port}/api/v1`, 'Bootstrap');
  Logger.log(`🛡  Xavfsizlik: helmet + rate-limit (150/min)`, 'Bootstrap');
}

void bootstrap();
