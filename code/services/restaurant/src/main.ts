import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.enableCors();

  const port = process.env.RESTAURANT_PORT ?? 3003;
  await app.listen(port);

  Logger.log(`🍽  Restaurant servisi: http://localhost:${port}/api/v1`, 'Bootstrap');
}

void bootstrap();
