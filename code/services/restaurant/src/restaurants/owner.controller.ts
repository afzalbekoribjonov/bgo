import { Body, Controller, Param, Patch, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { AssignOwnerDto } from './dto/assign-owner.dto';
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

  @Patch(':id/owner')
  async assignOwner(@Param('id') id: string, @Body() dto: AssignOwnerDto) {
    return { success: true, data: await this.service.assignOwner(id, dto.ownerUserId) };
  }
}
