import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { KitchenCredentialService } from './kitchen-credential.service';

class KitchenLoginDto {
  @IsString()
  @MinLength(3)
  @MaxLength(64)
  username!: string;

  @IsString()
  @MinLength(4)
  @MaxLength(128)
  password!: string;
}

class SetCredentialDto {
  @IsString()
  restaurantId!: string;

  @IsString()
  @MinLength(3)
  @MaxLength(64)
  username!: string;

  @IsString()
  @MinLength(4)
  @MaxLength(128)
  password!: string;
}

/** Sayt kirishi (public): login/parol -> JWT (role restaurant). */
@Controller('auth/kitchen')
export class KitchenAuthController {
  constructor(private readonly service: KitchenCredentialService) {}

  @Post('login')
  @HttpCode(200)
  async login(@Body() dto: KitchenLoginDto) {
    return {
      success: true,
      data: await this.service.login(dto.username, dto.password),
    };
  }
}

/** Admin: oshxona login/parolini yaratadi/tekshiradi. */
@Controller('auth/admin/kitchen-credentials')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminKitchenCredentialController {
  constructor(private readonly service: KitchenCredentialService) {}

  @Post()
  async set(@Body() dto: SetCredentialDto) {
    return {
      success: true,
      data: await this.service.setCredential(
        dto.restaurantId,
        dto.username,
        dto.password,
      ),
    };
  }

  @Get(':restaurantId')
  async info(@Param('restaurantId') restaurantId: string) {
    return { success: true, data: await this.service.getInfo(restaurantId) };
  }
}
