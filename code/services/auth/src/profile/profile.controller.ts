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
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccessTokenPayload } from '../auth/jwt-payload.interface';
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
  constructor(private readonly profile: ProfileService) {}

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
}
