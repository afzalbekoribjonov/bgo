import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  IsIn,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { SellerCredentialService } from './seller-credential.service';

class SellerLoginDto {
  @IsString()
  @MinLength(3)
  @MaxLength(64)
  username!: string;

  @IsString()
  @MinLength(4)
  @MaxLength(128)
  password!: string;
}

class SetSellerCredentialDto {
  @IsString()
  sellerId!: string;

  @IsString()
  @MinLength(3)
  @MaxLength(64)
  username!: string;

  @IsString()
  @MinLength(4)
  @MaxLength(128)
  password!: string;

  @IsIn(['SHOP', 'CONSTRUCTION'])
  sellerType!: string;
}

/** Sayt kirishi (public): login/parol -> JWT (role seller). */
@Controller('auth/seller')
export class SellerAuthController {
  constructor(private readonly service: SellerCredentialService) {}

  @Post('login')
  @HttpCode(200)
  async login(@Body() dto: SellerLoginDto) {
    return {
      success: true,
      data: await this.service.login(dto.username, dto.password),
    };
  }
}

/** Admin: sotuvchi login/parolini yaratadi/tekshiradi. */
@Controller('auth/admin/seller-credentials')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminSellerCredentialController {
  constructor(private readonly service: SellerCredentialService) {}

  @Post()
  async set(@Body() dto: SetSellerCredentialDto) {
    return {
      success: true,
      data: await this.service.setCredential(
        dto.sellerId,
        dto.username,
        dto.password,
        dto.sellerType,
      ),
    };
  }

  @Get(':sellerId')
  async info(@Param('sellerId') sellerId: string) {
    return { success: true, data: await this.service.getInfo(sellerId) };
  }
}
