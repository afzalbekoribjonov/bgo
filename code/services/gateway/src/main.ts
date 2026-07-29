import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { AppModule } from './app.module';
import { setupProxies } from './proxy/setup-proxies';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bodyParser: false });

  // Xavfsizlik sarlavhalari (XSS, clickjacking, sniff himoyasi)
  app.use(
    helmet({
      crossOriginEmbedderPolicy: false, // mobile/CDN mosligi
      contentSecurityPolicy: false,     // gateway faqat API, HTML yo'q
      // Rasmlar (market/marketplace uploads) boshqa portdagi saytlarda
      // <img> orqali ochiladi — same-origin CORP ularni bloklab qo'yardi.
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );

  // DDoS himoyasi: IP bo'yicha umumiy so'rov limiti
  app.use(
    rateLimit({
      windowMs: 60 * 1000, // 1 daqiqa
      max: 200,
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

  // CORS: faqat ruxsat etilgan manzillar (brauzer xavfsizligi)
  // MUHIM: CORS proxy'dan OLDIN ro'yxatdan o'tishi kerak, aks holda
  // preflight OPTIONS so'rovlari proxy tomonidan ushlанади va ACAO sarlavhasi bo'lmaydi.
  const corsOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((o) => o.trim())
    : [
        'http://localhost:3200', // admin_web (dev)
        'http://localhost:3100', // restaurant_web (dev)
        'http://localhost:3300', // market_web (dev)
        'http://localhost:3400', // shops_web (dev)
        'http://localhost:3500', // seller_web (dev)
        'http://localhost:3000', // backup
        'http://localhost:3001', // backup
      ];

  app.enableCors({
    origin: corsOrigins,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Internal-Key'],
    credentials: true,
  });

  // Proxy: barcha API so'rovlarini tegishli servislarga yo'naltiradi
  setupProxies(app);

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const port = process.env.GATEWAY_PORT ?? 4000;
  await app.listen(port);

  Logger.log(`🚪 API Gateway ishga tushdi: http://localhost:${port}/api/v1`, 'Bootstrap');
  Logger.log(`❤️  Sog'liq tekshiruvi: http://localhost:${port}/api/v1/health`, 'Bootstrap');
  Logger.log(`🛡  Xavfsizlik: helmet + rate-limit (${corsOrigins.join(', ')})`, 'Bootstrap');
}

void bootstrap();
