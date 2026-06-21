import { Body, Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { SetRolesDto } from './dto/set-roles.dto';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';

/**
 * Foydalanuvchi va rol boshqaruvi — faqat admin. plan/08-admin-workspace.md
 * (hamkor/haydovchi tasdiqlash = rol berish).
 */
@Controller('auth/admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminUsersController {
  constructor(private readonly auth: AuthService) {}

  @Get('users')
  async users() {
    return { success: true, data: await this.auth.listUsers() };
  }

  @Patch('users/:id/roles')
  async setRoles(@Param('id') id: string, @Body() dto: SetRolesDto) {
    return { success: true, data: await this.auth.setRoles(id, dto.roles) };
  }
}
