import { Body, Controller, HttpCode, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { AssignOwnerDto } from './dto/assign-owner.dto';
import { AssignOwnerByPhoneDto, LookupOwnerDto } from './dto/owner-phone.dto';
import { RestaurantsService } from './restaurants.service';

/**
 * Oshxonaga ega biriktirish — faqat admin (hamkorlik tasdiqlash).
 * plan/08-admin-workspace.md
 */
@Controller('restaurants')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class OwnerController {
  constructor(private readonly service: RestaurantsService) {}

  /** Xom UUID bilan biriktirish (ichki/qo'lda ishlatish uchun saqlangan). */
  @Patch(':id/owner')
  async assignOwner(@Param('id') id: string, @Body() dto: AssignOwnerDto) {
    return { success: true, data: await this.service.assignOwner(id, dto.ownerUserId) };
  }

  /** Telefon raqami bo'yicha foydalanuvchini qidiradi (tasdiqlashdan oldin ko'rsatish). */
  @Post('owner-lookup')
  @HttpCode(200)
  async lookupOwner(@Body() dto: LookupOwnerDto) {
    return { success: true, data: await this.service.findOwnerCandidate(dto.phone) };
  }

  /** Egani telefon raqami bo'yicha biriktiradi — professional oqim (UUID kerak emas). */
  @Patch(':id/owner-by-phone')
  async assignOwnerByPhone(
    @Param('id') id: string,
    @Body() dto: AssignOwnerByPhoneDto,
  ) {
    return {
      success: true,
      data: await this.service.assignOwnerByPhone(id, dto.phone),
    };
  }
}
