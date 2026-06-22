import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import {
  RegisterDeviceTokenDto,
  RemoveDeviceTokenDto,
} from '../notifications/dto/device-token.dto';
import { NotificationService } from '../notifications/notification.service';
import { CreateAddressDto, UpdateAddressDto } from './dto/address.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ProfileService } from './profile.service';

/**
 * Mijoz profili + saqlangan manzillar. plan/05-customer-app.md
 * Har autentifikatsiya qilingan foydalanuvchi o'z profilini boshqaradi.
 */
@Controller('profile')
@UseGuards(JwtAuthGuard)
export class ProfileController {
  constructor(
    private readonly profile: ProfileService,
    private readonly notifications: NotificationService,
  ) {}

  @Patch()
  async update(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: UpdateProfileDto,
  ) {
    return { success: true, data: await this.profile.updateProfile(user.sub, dto) };
  }

  @Get('addresses')
  async listAddresses(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.profile.listAddresses(user.sub) };
  }

  @Post('addresses')
  async addAddress(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: CreateAddressDto,
  ) {
    return { success: true, data: await this.profile.addAddress(user.sub, dto) };
  }

  @Patch('addresses/:id')
  async updateAddress(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
    @Body() dto: UpdateAddressDto,
  ) {
    return {
      success: true,
      data: await this.profile.updateAddress(user.sub, id, dto),
    };
  }

  @Delete('addresses/:id')
  @HttpCode(200)
  async deleteAddress(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    await this.profile.deleteAddress(user.sub, id);
    return { success: true };
  }

  // ---------- Push qurilma tokenlari (FCM) ----------

  @Get('device-tokens')
  async listDeviceTokens(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.notifications.listTokens(user.sub) };
  }

  @Post('device-token')
  async registerDeviceToken(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    const data = await this.notifications.registerToken(
      user.sub,
      dto.token,
      dto.platform ?? 'android',
    );
    return { success: true, data };
  }

  /** Chiqishda/qurilma almashtirishda tokenni o'chirish. */
  @Post('device-token/remove')
  @HttpCode(200)
  async removeDeviceToken(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: RemoveDeviceTokenDto,
  ) {
    await this.notifications.unregisterToken(user.sub, dto.token);
    return { success: true };
  }
}
