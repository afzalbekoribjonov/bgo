import { INestApplication, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createProxyMiddleware } from 'http-proxy-middleware';

interface RouteDef {
  /** Shu prefiks bilan boshlanadigan yo'llar tegishli servisga yo'naltiriladi */
  prefix: string;
  /** Maqsad URL .env kaliti */
  envKey: string;
  /** Standart (dev) URL */
  fallback: string;
}

/**
 * Gateway marshrutlash jadvali. Yangi servis qo'shilganda shu yerga bitta qator.
 * To'liq yo'l (masalan /api/v1/auth/otp/request) o'zgartirilmasdan uzatiladi.
 */
const ROUTES: RouteDef[] = [
  { prefix: '/api/v1/auth', envKey: 'AUTH_SERVICE_URL', fallback: 'http://localhost:4001' },
  { prefix: '/api/v1/partners', envKey: 'AUTH_SERVICE_URL', fallback: 'http://localhost:4001' },
  { prefix: '/api/v1/profile', envKey: 'AUTH_SERVICE_URL', fallback: 'http://localhost:4001' },
  { prefix: '/api/v1/restaurants', envKey: 'RESTAURANT_SERVICE_URL', fallback: 'http://localhost:4003' },
  { prefix: '/api/v1/orders', envKey: 'ORDER_SERVICE_URL', fallback: 'http://localhost:4004' },
  { prefix: '/api/v1/kitchen', envKey: 'ORDER_SERVICE_URL', fallback: 'http://localhost:4004' },
  { prefix: '/api/v1/courier', envKey: 'ORDER_SERVICE_URL', fallback: 'http://localhost:4004' },
  { prefix: '/api/v1/admin', envKey: 'ORDER_SERVICE_URL', fallback: 'http://localhost:4004' },
  // Keyingi fazalarda:
  // { prefix: '/api/v1/users', envKey: 'USER_SERVICE_URL', fallback: 'http://localhost:3002' },
];

export function setupProxies(app: INestApplication): void {
  const config = app.get(ConfigService);
  const logger = new Logger('GatewayProxy');

  for (const route of ROUTES) {
    const target = config.get<string>(route.envKey) ?? route.fallback;
    app.use(
      createProxyMiddleware({
        pathFilter: (path) => path.startsWith(route.prefix),
        target,
        changeOrigin: true,
        on: {
          error: (err, _req, res) => {
            logger.error(`Proxy xato (${route.prefix} -> ${target}): ${err.message}`);
            if ('writeHead' in res && !res.headersSent) {
              (res as import('http').ServerResponse).writeHead(502, {
                'Content-Type': 'application/json',
              });
              (res as import('http').ServerResponse).end(
                JSON.stringify({
                  success: false,
                  error: { code: 'SERVICE_UNAVAILABLE', message: 'Servis vaqtincha ishlamayapti' },
                }),
              );
            }
          },
        },
      }),
    );
    logger.log(`Proxy: ${route.prefix}/* -> ${target}`);
  }
}
