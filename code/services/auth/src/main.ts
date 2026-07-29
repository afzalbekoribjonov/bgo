import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Xavfsizlik sarlavhalari
  app.use(helmet());

  // OTP so'rov — eng qattiq limit (SMS spam oldini olish)
  // 5 daqiqada faqat 5 ta OTP so'rovi ruxsat etiladi
  app.use(
    '/api/v1/auth/otp/request',
    rateLimit({
      windowMs: 5 * 60 * 1000, // 5 daqiqa
      max: 5,
      standardHeaders: true,
      legacyHeaders: false,
      message: { message: "OTP so'rov limiti to'ldi. 5 daqiqadan so'ng urinib ko'ring." },
    }),
  );

  // Auth endpointlari — o'rta limit (brute-force himoyasi)
  app.use(
    '/api/v1/auth',
    rateLimit({
      windowMs: 60 * 1000, // 1 daqiqa
      max: 30,
      message: { message: "Juda ko'p urinish. Keyinroq urinib ko'ring." },
    }),
  );

  // Umumiy limit
  app.use(
    rateLimit({
      windowMs: 60 * 1000,
      max: 150,
      standardHeaders: true,
      legacyHeaders: false,
      message: { message: "Juda ko'p so'rov yuborildi. Keyinroq urinib ko'ring." },
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

  // Ichki servis — CORS faqat gateway va local
  const corsOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((o) => o.trim())
    : ['http://localhost:4000', 'http://localhost:3000', 'http://localhost:3100'];

  app.enableCors({
    origin: corsOrigins,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Internal-Key'],
    credentials: true,
  });

  const port = process.env.AUTH_PORT ?? 3001;
  await app.listen(port);

  Logger.log(`🔐 Auth servisi: http://localhost:${port}/api/v1`, 'Bootstrap');
  Logger.log(`🛡  Xavfsizlik: helmet + OTP rate-limit (5/5min) + auth limit (30/min)`, 'Bootstrap');
}

void bootstrap();
