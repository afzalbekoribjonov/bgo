import { Body, Controller, Headers, HttpCode, Post } from '@nestjs/common';
import { TelegramService } from './telegram.service';

/**
 * Telegram bot webhook — bot yangilanishlari (Telegram serveri chaqiradi).
 * Ochiq endpoint; ixtiyoriy maxfiy token (X-Telegram-Bot-Api-Secret-Token).
 */
@Controller('auth/telegram')
export class TelegramController {
  constructor(private readonly telegram: TelegramService) {}

  @Post('webhook')
  @HttpCode(200)
  async webhook(
    @Body() update: Record<string, unknown>,
    @Headers('x-telegram-bot-api-secret-token') secret?: string,
  ) {
    await this.telegram.processUpdate(update, secret);
    return { ok: true };
  }
}
