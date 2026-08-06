import { Body, Controller, Get, Headers, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import { localeFromHeader } from '@beshariq/i18n';
import { CreateCommentDto } from './dto/comment.dto';
import { MarketService } from './market.service';

/** Ochiq katalog — mahsulot ko'rish token'siz ham ishlaydi (WebView ko'rish rejimi). */
@Controller('market')
export class CatalogController {
  constructor(
    private readonly service: MarketService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  /**
   * Token bo'lsa foydalanuvchini aniqlaydi (shaxsiylashtirilgan `liked`
   * maydoni uchun), bo'lmasa yoki yaroqsiz bo'lsa jim o'tkazib yuboradi —
   * mahsulot detali token'siz ham ochiladi (WebView ko'rish rejimi).
   */
  private async optionalUser(authHeader?: string): Promise<string | undefined> {
    const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : undefined;
    if (!token) return undefined;
    try {
      const payload = await this.jwt.verifyAsync<AccessTokenPayload>(token, {
        secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      });
      return payload.sub;
    } catch {
      return undefined;
    }
  }

  @Get('categories')
  async categories(@Headers('accept-language') lang?: string) {
    return {
      success: true,
      data: await this.service.listPublicCategories(localeFromHeader(lang)),
    };
  }

  @Get('products')
  async products(
    @Headers('accept-language') lang?: string,
    @Query('categoryId') categoryId?: string,
    @Query('q') q?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return {
      success: true,
      data: await this.service.listProducts(localeFromHeader(lang), {
        categoryId,
        q,
        page: Math.max(1, Number(page) || 1),
        pageSize: Math.min(50, Math.max(1, Number(pageSize) || 20)),
      }),
    };
  }

  @Get('pickup-locations')
  async pickupLocations() {
    return { success: true, data: await this.service.listPickupLocations() };
  }

  /** Checkout'dan oldin do'kon holatini (yopiqmi/minimal summa) ko'rsatish uchun — token shart emas. */
  @Get('settings')
  async settings() {
    const s = await this.service.getSettings();
    return {
      success: true,
      data: {
        minOrderAmount: s.minOrderAmount,
        isAcceptingOrders: s.isAcceptingOrders,
      },
    };
  }

  @Get('products/:id')
  async detail(
    @Param('id') id: string,
    @Headers('accept-language') lang?: string,
    @Headers('authorization') authHeader?: string,
  ) {
    const userId = await this.optionalUser(authHeader);
    return {
      success: true,
      data: await this.service.getProduct(id, localeFromHeader(lang), userId),
    };
  }

  @Post('products/:id/like')
  @UseGuards(JwtAuthGuard)
  async like(@Param('id') id: string, @CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.likeProduct(id, user.sub) };
  }

  @Get('products/:id/comments')
  async comments(@Param('id') id: string) {
    return { success: true, data: await this.service.listComments(id) };
  }

  @Post('products/:id/comments')
  @UseGuards(JwtAuthGuard)
  async addComment(
    @Param('id') id: string,
    @Body() dto: CreateCommentDto,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.addComment(id, user.sub, dto.text),
    };
  }
}
