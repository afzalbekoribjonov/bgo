import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { setupProxies } from './proxy/setup-proxies';

async function bootstrap() {
  // bodyParser: false — gateway so'rovlarni o'zgartirmasdan servislarga uzatadi
  // (proxy oqimi body-parser bilan to'qnashmasligi uchun).
  const app = await NestFactory.create(AppModule, { bodyParser: false });

  // Servislarga yo'naltirish (auth, ...) — Nest router'idan oldin.
  setupProxies(app);

  // Gateway'ning o'z endpoint'lari /api/v1 ostida (masalan /health)
  app.setGlobalPrefix('api/v1');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // MVP: barcha origin'larga ruxsat (keyin cheklanadi)
  app.enableCors();

  const port = process.env.GATEWAY_PORT ?? 4000;
  await app.listen(port);

  Logger.log(`🚪 API Gateway ishga tushdi: http://localhost:${port}/api/v1`, 'Bootstrap');
  Logger.log(`❤️  Sog'liq tekshiruvi: http://localhost:${port}/api/v1/health`, 'Bootstrap');
}

void bootstrap();
