import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return {
      success: true,
      data: {
        service: 'market',
        status: 'ok',
        timestamp: new Date().toISOString(),
      },
    };
  }
}
