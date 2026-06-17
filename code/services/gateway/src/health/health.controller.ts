import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  /**
   * GET /api/v1/health
   * Gateway tirik ekanligini tekshirish (monitoring, load balancer uchun).
   */
  @Get()
  check() {
    return {
      success: true,
      data: {
        service: 'gateway',
        status: 'ok',
        version: process.env.npm_package_version ?? '0.1.0',
        uptime: Math.round(process.uptime()),
        timestamp: new Date().toISOString(),
      },
    };
  }
}
