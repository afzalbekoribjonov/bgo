import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { InternalKeyGuard } from '../notifications/internal-key.guard';
import { UserRepository } from './user.repository';

/** Servislararo javob shakli — foydalanuvchining ommaviy ma'lumoti. */
interface PublicUserLookup {
  id: string;
  phone: string;
  fullName: string | null;
}

function toPublic(u: { id: string; phone: string; fullName?: string } | null): PublicUserLookup | null {
  if (!u) return null;
  return { id: u.id, phone: u.phone, fullName: u.fullName ?? null };
}

/**
 * Servislararo: foydalanuvchini telefon/ID bo'yicha topadi (masalan, restaurant
 * servisi oshxona egasini telefon raqami bilan bog'lash uchun). `x-internal-key`
 * bilan himoyalangan — gateway bu yo'lni tashqariga chiqarmaydi.
 */
@Controller('internal/users')
@UseGuards(InternalKeyGuard)
export class InternalUsersController {
  constructor(private readonly users: UserRepository) {}

  /** GET /api/v1/internal/users/by-phone/:phone -> {id,phone,fullName} | null */
  @Get('by-phone/:phone')
  async byPhone(@Param('phone') phone: string) {
    const user = await this.users.findByPhone(phone);
    return { success: true, data: toPublic(user) };
  }

  /** GET /api/v1/internal/users/:id -> {id,phone,fullName} | null */
  @Get(':id')
  async byId(@Param('id') id: string) {
    const user = await this.users.findById(id);
    return { success: true, data: toPublic(user) };
  }
}
