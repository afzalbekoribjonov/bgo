import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  AccessTokenPayload,
  CurrentUser,
  JwtAuthGuard,
  Roles,
  RolesGuard,
} from '@beshariq/nest-auth';
import { SellerType } from '../../prisma/generated/client';
import { SendChatMessageDto } from './dto/chat-message.dto';
import { UpdateSellerProfileDto } from './dto/seller.dto';
import { CreateProductDto, UpdateProductDto } from './dto/product.dto';
import { MarketplaceService } from './marketplace.service';

/** Sotuvchi paneli (seller_web) — faqat 'seller' roli, o'z sellerId'siga cheklangan. */
@Controller('marketplace/seller')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('seller')
export class SellerController {
  constructor(private readonly service: MarketplaceService) {}

  private sellerId(user: AccessTokenPayload): string {
    if (!user.sellerId) throw new ForbiddenException('Sotuvchi aniqlanmadi');
    return user.sellerId;
  }

  // ---- Mahsulotlar ----

  @Get('products')
  async products(@CurrentUser() user: AccessTokenPayload) {
    return {
      success: true,
      data: await this.service.sellerListProducts(this.sellerId(user)),
    };
  }

  @Post('products')
  async createProduct(
    @Body() dto: CreateProductDto,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.sellerCreateProduct(
        this.sellerId(user),
        user.sellerType as SellerType,
        dto,
      ),
    };
  }

  @Patch('products/:id')
  async updateProduct(
    @Param('id') id: string,
    @Body() dto: UpdateProductDto,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.sellerUpdateProduct(this.sellerId(user), id, dto),
    };
  }

  @Delete('products/:id')
  async deleteProduct(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.sellerDeleteProduct(this.sellerId(user), id),
    };
  }

  // ---- Chat ----

  @Get('chats')
  async chats(@CurrentUser() user: AccessTokenPayload) {
    return {
      success: true,
      data: await this.service.sellerListChatThreads(this.sellerId(user)),
    };
  }

  @Get('chats/:customerId/messages')
  async chatMessages(
    @Param('customerId') customerId: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.listChatMessages(this.sellerId(user), customerId),
    };
  }

  @Post('chats/:customerId/messages')
  async sendChat(
    @Param('customerId') customerId: string,
    @Body() dto: SendChatMessageDto,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    await this.service.sellerMarkChatSeen(this.sellerId(user), customerId);
    return {
      success: true,
      data: await this.service.sendChatMessage(
        this.sellerId(user),
        customerId,
        'SELLER',
        dto.text,
      ),
    };
  }

  // ---- Profil ----

  @Get('profile')
  async profile(@CurrentUser() user: AccessTokenPayload) {
    return {
      success: true,
      data: await this.service.getSellerProfileRaw(this.sellerId(user)),
    };
  }

  @Patch('profile')
  async updateProfile(
    @Body() dto: UpdateSellerProfileDto,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.updateSellerProfile(this.sellerId(user), dto),
    };
  }
}
