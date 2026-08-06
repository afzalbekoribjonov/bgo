import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { INTERNAL_KEY_HEADER, matchesInternalKey } from '@beshariq/nest-auth';
import {
  buildCorsOptions,
  resolveCorsOrigins,
  VALIDATION_PIPE_OPTIONS,
} from '@beshariq/nest-bootstrap';
import helmet from 'helmet';
import compression from 'compression';
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
      // Ichki servis so'rovlari limitlanmaydi
      skip: (req) => matchesInternalKey(req.headers[INTERNAL_KEY_HEADER]),
    }),
  );

  // CORS: faqat ruxsat etilgan manzillar (brauzer xavfsizligi)
  // MUHIM: CORS proxy'dan OLDIN ro'yxatdan o'tishi kerak, aks holda
  // preflight OPTIONS so'rovlari proxy tomonidan ushlанади va ACAO sarlavhasi bo'lmaydi.
  const corsOrigins = resolveCorsOrigins([
    'http://localhost:3200', // admin_web (dev)
    'http://localhost:3100', // restaurant_web (dev)
    'http://localhost:3300', // market_web (dev)
    'http://localhost:3400', // shops_web (dev)
    'http://localhost:3500', // seller_web (dev)
    'http://localhost:3000', // backup
    'http://localhost:3001', // backup
  ]);
  app.enableCors(buildCorsOptions(corsOrigins));

  // Javoblarni siqish (gzip/br) — sahifalangan ro'yxatlar kabi katta JSON
  // javoblar tarmoqda kichikroq bo'ladi. MUHIM: proxy'dan OLDIN turishi
  // shart — aks holda javob oqimi allaqachon yozib bo'lingan bo'ladi va
  // siqish qo'llanmaydi. Rasm kabi allaqachon siqilgan turlar avtomatik
  // o'tkazib yuboriladi (compression'ning standart filtri).
  app.use(compression());

  // Proxy: barcha API so'rovlarini tegishli servislarga yo'naltiradi
  setupProxies(app);

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(new ValidationPipe(VALIDATION_PIPE_OPTIONS));

  const port = process.env.GATEWAY_PORT ?? 4000;
  await app.listen(port);

  Logger.log(`🚪 API Gateway ishga tushdi: http://localhost:${port}/api/v1`, 'Bootstrap');
  Logger.log(`❤️  Sog'liq tekshiruvi: http://localhost:${port}/api/v1/health`, 'Bootstrap');
  Logger.log(`🛡  Xavfsizlik: helmet + rate-limit (${corsOrigins.join(', ')})`, 'Bootstrap');
}

void bootstrap();
