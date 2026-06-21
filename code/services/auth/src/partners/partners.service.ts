import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { UserRepository } from '../users/user.repository';
import { ApplyPartnerDto } from './dto/apply-partner.dto';
import { PartnerStatus, PartnerType } from './partner.entity';
import { PartnerRepository } from './partner.repository';

/** Hamkorlik (oshxona/haydovchi) arizalari. plan/08-admin-workspace.md */
@Injectable()
export class PartnersService {
  private readonly logger = new Logger(PartnersService.name);

  constructor(
    private readonly repo: PartnerRepository,
    private readonly users: UserRepository,
  ) {}

  /** Foydalanuvchi ariza yuboradi (telefon token'dan). */
  async apply(userId: string, phone: string, dto: ApplyPartnerDto) {
    const pending = await this.repo.findPending(userId, dto.type);
    if (pending) {
      throw new BadRequestException(
        "Sizda ko'rib chiqilayotgan ariza bor. Iltimos, kuting.",
      );
    }
    return this.repo.create({
      userId,
      phone,
      fullName: dto.fullName,
      type: dto.type,
      note: dto.note,
    });
  }

  listMine(userId: string) {
    return this.repo.findByUser(userId);
  }

  // ---------- Admin ----------

  adminList(status?: PartnerStatus) {
    return this.repo.findAll(status);
  }

  /** Holatni o'zgartirish; APPROVED bo'lsa tegishli rolni beradi. */
  async adminUpdateStatus(id: string, status: PartnerStatus) {
    const app = await this.repo.findById(id);
    if (!app) throw new NotFoundException('Ariza topilmadi');
    if (app.status !== 'PENDING') {
      throw new BadRequestException('Ariza allaqachon ko‘rib chiqilgan');
    }

    if (status === 'APPROVED') {
      await this.grantRole(app.userId, app.type);
    }
    const updated = await this.repo.updateStatus(id, status);
    this.logger.log(`Hamkorlik arizasi ${id} -> ${status}`);
    return updated;
  }

  /** Ariza turiga mos rolni foydalanuvchiga qo'shadi (bor bo'lsa o'tkazib yuboradi). */
  private async grantRole(userId: string, type: PartnerType) {
    const user = await this.users.findById(userId);
    if (!user) throw new NotFoundException('Foydalanuvchi topilmadi');
    const role = type === 'DRIVER' ? 'driver' : 'restaurant';
    if (!user.roles.includes(role)) {
      await this.users.update(userId, { roles: [...user.roles, role] });
      this.logger.log(`Rol berildi: ${user.phone} -> ${role}`);
    }
  }
}
