import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePromoDto, UpdatePromoDto } from './dto/promo.dto';

export interface AppliedPromo {
  code: string;
  discount: number;
}

/**
 * Promokod / aksiya boshqaruvi va qo'llash. plan/11-pricing-promo.md
 * TODO: per-user limit, amal muddati, xizmat ko'lami (FOOD/TAXI).
 */
@Injectable()
export class PromoService {
  constructor(private readonly prisma: PrismaService) {}

  /** Promokodni tekshiradi va chegirmani hisoblaydi (itemsTotal asosida). */
  async apply(rawCode: string, itemsTotal: number): Promise<AppliedPromo> {
    const code = rawCode.trim().toUpperCase();
    const promo = await this.prisma.promoCode.findUnique({ where: { code } });
    if (!promo || !promo.active) {
      throw new BadRequestException('Promokod yaroqsiz yoki faol emas');
    }
    if (itemsTotal < promo.minOrder) {
      throw new BadRequestException(
        `Minimal buyurtma summasi: ${promo.minOrder} so'm`,
      );
    }
    let discount =
      promo.type === 'PERCENT'
        ? Math.round((itemsTotal * promo.value) / 100)
        : promo.value;
    if (promo.type === 'PERCENT' && promo.maxDiscount != null) {
      discount = Math.min(discount, promo.maxDiscount);
    }
    discount = Math.min(discount, itemsTotal); // chegirma taomlar summasidan oshmaydi
    return { code: promo.code, discount };
  }

  async incrementUsage(code: string): Promise<void> {
    try {
      await this.prisma.promoCode.update({
        where: { code },
        data: { usedCount: { increment: 1 } },
      });
    } catch {
      // promokod o'chirilgan bo'lsa — e'tiborsiz
    }
  }

  // ---------- Admin CRUD ----------

  list() {
    return this.prisma.promoCode.findMany({ orderBy: { createdAt: 'desc' } });
  }

  create(dto: CreatePromoDto) {
    return this.prisma.promoCode.create({
      data: { ...dto, code: dto.code.trim().toUpperCase() },
    });
  }

  async update(id: string, dto: UpdatePromoDto) {
    await this.require(id);
    return this.prisma.promoCode.update({ where: { id }, data: dto });
  }

  async remove(id: string): Promise<void> {
    await this.require(id);
    await this.prisma.promoCode.delete({ where: { id } });
  }

  private async require(id: string) {
    const found = await this.prisma.promoCode.findUnique({ where: { id } });
    if (!found) throw new NotFoundException('Promokod topilmadi');
    return found;
  }
}
