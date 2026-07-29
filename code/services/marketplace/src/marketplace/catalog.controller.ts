import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  AccessTokenPayload,
  CurrentUser,
  JwtAuthGuard,
} from '@beshariq/nest-auth';
import { SellerType } from '../../prisma/generated/client';
import { localeFromHeader } from '@beshariq/i18n';
import { SendChatMessageDto } from './dto/chat-message.dto';
import { MarketplaceService } from './marketplace.service';

function parseSellerType(value?: string): SellerType {
  if (value === 'SHOP' || value === 'CONSTRUCTION') return value;
  throw new BadRequestException(
    "sellerType 'SHOP' yoki 'CONSTRUCTION' bo'lishi kerak",
  );
}

/** Ochiq katalog (Do'konlar + Qurilishda foydali) — token'siz ham ishlaydi. */
@Controller('marketplace')
export class CatalogController {
  constructor(private readonly service: MarketplaceService) {}

  @Get('categories')
  async categories(
    @Query('sellerType') sellerType: string,
    @Headers('accept-language') lang?: string,
  ) {
    return {
      success: true,
      data: await this.service.listPublicCategories(
        parseSellerType(sellerType),
        localeFromHeader(lang),
      ),
    };
  }

  @Get('products')
  async products(
    @Query('sellerType') sellerType: string,
    @Query('categoryId') categoryId?: string,
    @Query('lat') lat?: string,
    @Query('lng') lng?: string,
    @Headers('accept-language') lang?: string,
  ) {
    // Mijoz joylashuvi berilsa — eng yaqin do'kon mahsulotlari birinchi
    const latNum = lat ? Number(lat) : NaN;
    const lngNum = lng ? Number(lng) : NaN;
    const near =
      Number.isFinite(latNum) && Number.isFinite(lngNum)
        ? { lat: latNum, lng: lngNum }
        : undefined;
    return {
      success: true,
      data: await this.service.listProducts(
        parseSellerType(sellerType),
        localeFromHeader(lang),
        categoryId,
        near,
      ),
    };
  }

  @Get('products/:id')
  async product(
    @Param('id') id: string,
    @Headers('accept-language') lang?: string,
  ) {
    return {
      success: true,
      data: await this.service.getProduct(id, localeFromHeader(lang)),
    };
  }

  @Get('sellers/:id')
  async seller(
    @Param('id') id: string,
    @Headers('accept-language') lang?: string,
  ) {
    return {
      success: true,
      data: await this.service.getSellerProfile(id, localeFromHeader(lang)),
    };
  }

  // ---- Mijoz <-> sotuvchi chat ----

  @Get('chat/threads')
  @UseGuards(JwtAuthGuard)
  async myThreads(@CurrentUser() user: AccessTokenPayload) {
    return {
      success: true,
      data: await this.service.listCustomerThreads(user.sub),
    };
  }

  @Get('chat/:sellerId/messages')
  @UseGuards(JwtAuthGuard)
  async chatMessages(
    @Param('sellerId') sellerId: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.listChatMessages(sellerId, user.sub),
    };
  }

  @Post('chat/:sellerId/messages')
  @UseGuards(JwtAuthGuard)
  async sendChat(
    @Param('sellerId') sellerId: string,
    @Body() dto: SendChatMessageDto,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.sendChatMessage(
        sellerId,
        user.sub,
        'CUSTOMER',
        dto.text,
      ),
    };
  }
}
