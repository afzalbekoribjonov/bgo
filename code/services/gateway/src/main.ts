import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Barcha endpoint'lar /api/v1 ostida (14-api-design.md)
  app.setGlobalPrefix('api/v1');

  // Kirish ma'lumotlarini avtomatik validatsiya va tozalash
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // MVP: barcha origin'larga ruxsat (keyin cheklanadi)
  app.enableCors();

  const port = process.env.GATEWAY_PORT ?? 3000;
  await app.listen(port);

  Logger.log(`🚪 API Gateway ishga tushdi: http://localhost:${port}/api/v1`, 'Bootstrap');
  Logger.log(`❤️  Sog'liq tekshiruvi: http://localhost:${port}/api/v1/health`, 'Bootstrap');
}

void bootstrap();
