import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return {
      success: true,
      data: {
        service: 'restaurant',
        status: 'ok',
        timestamp: new Date().toISOString(),
      },
    };
  }
}
