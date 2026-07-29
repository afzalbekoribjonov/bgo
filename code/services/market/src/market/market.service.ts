import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { I18nString, pickLocale, SupportedLocale } from '@beshariq/i18n';
import { PrismaService } from '../prisma/prisma.service';
import { UserInfoClient } from '../user-client/user-info.client';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import {
  AdjustStockDto,
  CreateProductDto,
  UpdateProductDto,
} from './dto/product.dto';
import {
  CreatePickupLocationDto,
  UpdatePickupLocationDto,
} from './dto/pickup-location.dto';

@Injectable()
export class MarketService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userInfo: UserInfoClient,
  ) {}

  // ---------- Public katalog ----------

  /** Ochiq katalog uchun — nom tilga moslangan matn (obyekt emas). */
  async listPublicCategories(locale: SupportedLocale) {
    const categories = await this.prisma.category.findMany({
      orderBy: { sortOrder: 'asc' },
    });
    return categories.map((c) => ({
      id: c.id,
      name: pickLocale(c.name as unknown as I18nString, locale),
      sortOrder: c.sortOrder,
    }));
  }

  /** Admin tahrirlash uchun — nom xom ko'p tilli obyekt sifatida. */
  async listCategories() {
    const categories = await this.prisma.category.findMany({
      orderBy: { sortOrder: 'asc' },
    });
    return categories.map((c) => ({
      id: c.id,
      name: c.name as unknown as I18nString,
      sortOrder: c.sortOrder,
    }));
  }

  async listProducts(locale: SupportedLocale, categoryId?: string) {
    const products = await this.prisma.product.findMany({
      where: { isActive: true, ...(categoryId ? { categoryId } : {}) },
      orderBy: { createdAt: 'desc' },
    });
    return products.map((p) => this.toPublicProduct(p, locale));
  }

  async getProduct(id: string, locale: SupportedLocale, userId?: string) {
    const product = await this.requireProduct(id);
    const liked = userId
      ? !!(await this.prisma.productLike.findUnique({
          where: { productId_userId: { productId: id, userId } },
        }))
      : false;
    return { ...this.toPublicProduct(product, locale), liked };
  }

  async listPickupLocations() {
    const locations = await this.prisma.pickupLocation.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
    return locations;
  }

  // ---------- Layk (bir martalik) ----------

  async likeProduct(productId: string, userId: string) {
    await this.requireProduct(productId);
    try {
      await this.prisma.productLike.create({ data: { productId, userId } });
    } catch (err) {
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        throw new ConflictException('Siz bu mahsulotni allaqachon yoqtirgansiz');
      }
      throw err;
    }
    const product = await this.prisma.product.update({
      where: { id: productId },
      data: { likesCount: { increment: 1 } },
    });
    return { likesCount: product.likesCount, liked: true };
  }

  // ---------- Izohlar ----------

  /** Izohlarni mijoz ism/telefoni bilan boyitib qaytaradi (best-effort — auth servisidan). */
  async listComments(productId: string) {
    await this.requireProduct(productId);
    const comments = await this.prisma.productComment.findMany({
      where: { productId },
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(
      comments.map(async (c) => ({ ...c, user: await this.userInfo.getUserInfo(c.userId) })),
    );
  }

  async addComment(productId: string, userId: string, text: string) {
    await this.requireProduct(productId);
    return this.prisma.productComment.create({
      data: { productId, userId, text },
    });
  }

  async deleteComment(id: string) {
    await this.prisma.productComment
      .delete({ where: { id } })
      .catch(() => {
        throw new NotFoundException('Izoh topilmadi');
      });
    return { ok: true };
  }

  // ---------- Support chat ----------

  async listSupportMessages(customerId: string) {
    return this.prisma.supportMessage.findMany({
      where: { customerId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async sendSupportMessage(
    customerId: string,
    senderRole: 'CUSTOMER' | 'SUPPORT',
    text: string,
  ) {
    return this.prisma.supportMessage.create({
      data: { customerId, senderRole, text },
    });
  }

  /**
   * Admin: barcha suhbat "iplari" — mijoz (ism+telefon) + oxirgi xabar +
   * o'qilmagan son. Ism/telefon best-effort (auth servisi javob bermasa ham
   * ro'yxat ko'rsatiladi, faqat ID qoladi).
   */
  async listSupportThreads() {
    const messages = await this.prisma.supportMessage.findMany({
      orderBy: { createdAt: 'desc' },
    });
    const byCustomer = new Map<string, typeof messages>();
    for (const m of messages) {
      const list = byCustomer.get(m.customerId) ?? [];
      list.push(m);
      byCustomer.set(m.customerId, list);
    }
    const threads = [...byCustomer.entries()].map(([customerId, list]) => ({
      customerId,
      lastMessage: list[0].text,
      lastMessageAt: list[0].createdAt,
      unseenCount: list.filter((m) => m.senderRole === 'CUSTOMER' && !m.seenAt)
        .length,
    }));
    return Promise.all(
      threads.map(async (t) => ({
        ...t,
        customer: await this.userInfo.getUserInfo(t.customerId),
      })),
    );
  }

  async markSupportSeen(customerId: string) {
    await this.prisma.supportMessage.updateMany({
      where: { customerId, senderRole: 'CUSTOMER', seenAt: null },
      data: { seenAt: new Date() },
    });
    return { ok: true };
  }

  // ---------- Admin: kategoriyalar ----------

  createCategory(dto: CreateCategoryDto) {
    return this.prisma.category.create({
      data: {
        name: { ...dto.name } as Prisma.InputJsonValue,
        sortOrder: dto.sortOrder ?? 0,
      },
    });
  }

  async updateCategory(id: string, dto: UpdateCategoryDto) {
    await this.requireCategory(id);
    return this.prisma.category.update({
      where: { id },
      data: {
        ...(dto.name ? { name: { ...dto.name } as Prisma.InputJsonValue } : {}),
        ...(dto.sortOrder !== undefined ? { sortOrder: dto.sortOrder } : {}),
      },
    });
  }

  async deleteCategory(id: string) {
    await this.requireCategory(id);
    const productCount = await this.prisma.product.count({
      where: { categoryId: id },
    });
    if (productCount > 0) {
      throw new ConflictException(
        "Bu kategoriyada mahsulotlar bor — avval ularni ko'chiring yoki o'chiring",
      );
    }
    await this.prisma.category.delete({ where: { id } });
    return { ok: true };
  }

  // ---------- Admin: mahsulotlar ----------

  async adminListProducts() {
    const products = await this.prisma.product.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return products.map((p) => ({
      ...p,
      name: p.name as unknown as I18nString,
      description: p.description as unknown as I18nString | null,
      sizes: p.sizes,
    }));
  }

  async createProduct(dto: CreateProductDto) {
    await this.requireCategory(dto.categoryId);
    return this.prisma.product.create({
      data: {
        categoryId: dto.categoryId,
        name: { ...dto.name } as Prisma.InputJsonValue,
        description: dto.description
          ? ({ ...dto.description } as Prisma.InputJsonValue)
          : Prisma.JsonNull,
        price: dto.price,
        stockQty: dto.stockQty ?? 0,
        imageUrls: dto.imageUrls ?? [],
        sizes: this.normalizeSizes(dto.sizes),
        isActive: dto.isActive ?? true,
      },
    });
  }

  async updateProduct(id: string, dto: UpdateProductDto) {
    await this.requireProduct(id);
    if (dto.categoryId) await this.requireCategory(dto.categoryId);
    return this.prisma.product.update({
      where: { id },
      data: {
        ...(dto.categoryId ? { categoryId: dto.categoryId } : {}),
        ...(dto.name ? { name: { ...dto.name } as Prisma.InputJsonValue } : {}),
        ...(dto.description !== undefined
          ? {
              description: dto.description
                ? ({ ...dto.description } as Prisma.InputJsonValue)
                : Prisma.JsonNull,
            }
          : {}),
        ...(dto.price !== undefined ? { price: dto.price } : {}),
        ...(dto.imageUrls !== undefined ? { imageUrls: dto.imageUrls } : {}),
        ...(dto.sizes !== undefined ? { sizes: this.normalizeSizes(dto.sizes) } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
    });
  }

  async deleteProduct(id: string) {
    await this.requireProduct(id);
    await this.prisma.product.delete({ where: { id } });
    return { ok: true };
  }

  /** Zaxirani +/- qiladi (admin qo'lda, yoki keyinchalik buyurtma tizimi). 0 dan pastga tushmaydi. */
  async adjustStock(id: string, dto: AdjustStockDto) {
    const product = await this.requireProduct(id);
    const next = Math.max(0, product.stockQty + dto.delta);
    return this.prisma.product.update({
      where: { id },
      data: { stockQty: next },
    });
  }

  // ---------- Admin: pickup joylar ----------

  listAllPickupLocations() {
    return this.prisma.pickupLocation.findMany({ orderBy: { name: 'asc' } });
  }

  createPickupLocation(dto: CreatePickupLocationDto) {
    return this.prisma.pickupLocation.create({ data: dto });
  }

  async updatePickupLocation(id: string, dto: UpdatePickupLocationDto) {
    await this.requirePickupLocation(id);
    return this.prisma.pickupLocation.update({ where: { id }, data: dto });
  }

  /**
   * Joyni o'chirish emas — faolsizlantirish. Eski buyurtmalar `pickupLocationId`
   * orqali shu yozuvga bog'langan (nomi snapshot qilinmagan), shuning uchun
   * qatorni o'chirsak buyurtma tarixi "joy topilmadi" holatiga tushib qoladi.
   */
  async deletePickupLocation(id: string) {
    await this.requirePickupLocation(id);
    await this.prisma.pickupLocation.update({
      where: { id },
      data: { isActive: false },
    });
    return { ok: true };
  }

  // ---------- Internal (order servisi uchun — Faza A1) ----------

  /** Buyurtma yaratishda narx/zaxira snapshoti (+ o'lcham tekshiruvi uchun ro'yxat). */
  async internalGetProduct(id: string) {
    const product = await this.requireProduct(id);
    return {
      id: product.id,
      name: pickLocale(product.name as unknown as I18nString, 'uz'),
      price: product.price,
      stockQty: product.stockQty,
      sizes: product.sizes,
    };
  }

  /** Buyurtma yaratilganda zaxirani band qiladi (atomik, yetarsiz bo'lsa xato). */
  async internalReserveStock(id: string, qty: number) {
    const result = await this.prisma.product.updateMany({
      where: { id, stockQty: { gte: qty } },
      data: { stockQty: { decrement: qty } },
    });
    if (result.count === 0) {
      throw new ConflictException('Zaxira yetarli emas');
    }
    return { ok: true };
  }

  /** Buyurtma bekor qilinganda zaxirani qaytaradi. */
  async internalReleaseStock(id: string, qty: number) {
    await this.prisma.product.update({
      where: { id },
      data: { stockQty: { increment: qty } },
    });
    return { ok: true };
  }

  /** Buyurtma yaratishda pickup joy (haydovchi/mijoz boradigan manzil) tekshiruvi. */
  async internalGetPickupLocation(id: string) {
    const location = await this.requirePickupLocation(id);
    return {
      id: location.id,
      name: location.name,
      address: location.address,
      lat: location.lat,
      lng: location.lng,
    };
  }

  // ---------- yordamchilar ----------

  private async requireProduct(id: string) {
    const product = await this.prisma.product.findUnique({ where: { id } });
    if (!product) throw new NotFoundException('Mahsulot topilmadi');
    return product;
  }

  private async requireCategory(id: string) {
    const category = await this.prisma.category.findUnique({ where: { id } });
    if (!category) throw new NotFoundException('Kategoriya topilmadi');
    return category;
  }

  private async requirePickupLocation(id: string) {
    const location = await this.prisma.pickupLocation.findUnique({
      where: { id },
    });
    if (!location) throw new NotFoundException('Olib ketish joyi topilmadi');
    return location;
  }

  /** Bo'sh/takror o'lchamlarni tozalaydi, tartibni saqlaydi. */
  private normalizeSizes(sizes?: string[]): string[] {
    if (!sizes) return [];
    const seen = new Set<string>();
    const out: string[] = [];
    for (const raw of sizes) {
      const s = raw.trim();
      if (!s) continue;
      const key = s.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      out.push(s);
    }
    return out;
  }

  private toPublicProduct(
    p: {
      id: string;
      categoryId: string;
      name: unknown;
      description: unknown;
      price: number;
      stockQty: number;
      imageUrls: string[];
      sizes: string[];
      likesCount: number;
      ratingAvg: number | null;
    },
    locale: SupportedLocale,
  ) {
    return {
      id: p.id,
      categoryId: p.categoryId,
      name: pickLocale(p.name as I18nString, locale),
      description: p.description
        ? pickLocale(p.description as I18nString, locale)
        : null,
      price: p.price,
      stockQty: p.stockQty,
      inStock: p.stockQty > 0,
      imageUrls: p.imageUrls,
      sizes: p.sizes,
      likesCount: p.likesCount,
      ratingAvg: p.ratingAvg,
    };
  }
}
