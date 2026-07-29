import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, SellerType } from '../../prisma/generated/client';
import { I18nString, pickLocale, SupportedLocale } from '@beshariq/i18n';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import { CreateSellerDto, UpdateSellerDto, UpdateSellerProfileDto } from './dto/seller.dto';
import { CreateProductDto, UpdateProductDto } from './dto/product.dto';

@Injectable()
export class MarketplaceService {
  constructor(private readonly prisma: PrismaService) {}

  // ---------- Ochiq katalog ----------

  async listPublicCategories(sellerType: SellerType, locale: SupportedLocale) {
    const categories = await this.prisma.category.findMany({
      where: { sellerType },
      orderBy: { sortOrder: 'asc' },
    });
    return categories.map((c) => ({
      id: c.id,
      name: pickLocale(c.name as unknown as I18nString, locale),
      sortOrder: c.sortOrder,
    }));
  }

  async listProducts(
    sellerType: SellerType,
    locale: SupportedLocale,
    categoryId?: string,
    near?: { lat: number; lng: number },
  ) {
    const products = await this.prisma.product.findMany({
      where: {
        sellerType,
        isActive: true,
        seller: { isActive: true },
        ...(categoryId ? { categoryId } : {}),
      },
      include: { seller: true },
    });
    const mixed = this.mixRandomAndRating(products).map((p) =>
      this.toPublicProduct(p, locale, near),
    );
    if (!near) return mixed;
    // Mijoz joylashuvi ma'lum: eng yaqin do'kon mahsulotlari birinchi;
    // joylashuvi kiritilmagan sotuvchilar oxirda (mix tartibida qoladi).
    return mixed.sort((a, b) => {
      if (a.distanceKm === null && b.distanceKm === null) return 0;
      if (a.distanceKm === null) return 1;
      if (b.distanceKm === null) return -1;
      return a.distanceKm - b.distanceKm;
    });
  }

  async getProduct(id: string, locale: SupportedLocale) {
    const product = await this.requireProduct(id);
    return this.toPublicProduct(product, locale);
  }

  async getSellerProfile(id: string, locale: SupportedLocale) {
    const seller = await this.requireSeller(id);
    const products = await this.prisma.product.findMany({
      where: { sellerId: id, isActive: true },
      orderBy: { createdAt: 'desc' },
    });
    return {
      id: seller.id,
      name: seller.name,
      description: seller.description,
      contactPhone: seller.contactPhone,
      sellerType: seller.sellerType,
      address: seller.address,
      lat: seller.lat,
      lng: seller.lng,
      products: products.map((p) => this.toPublicProduct({ ...p, seller }, locale)),
    };
  }

  // ---------- Mijoz <-> sotuvchi chat ----------

  async listChatMessages(sellerId: string, customerId: string) {
    await this.requireSeller(sellerId);
    return this.prisma.chatMessage.findMany({
      where: { sellerId, customerId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async sendChatMessage(
    sellerId: string,
    customerId: string,
    senderRole: 'CUSTOMER' | 'SELLER',
    text: string,
  ) {
    await this.requireSeller(sellerId);
    return this.prisma.chatMessage.create({
      data: { sellerId, customerId, senderRole, text },
    });
  }

  /** Mijoz o'zi yozgan barcha sotuvchilar bilan suhbatlari — "Xabarlarim". */
  async listCustomerThreads(customerId: string) {
    const messages = await this.prisma.chatMessage.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
    });
    const bySeller = new Map<string, typeof messages>();
    for (const m of messages) {
      const list = bySeller.get(m.sellerId) ?? [];
      list.push(m);
      bySeller.set(m.sellerId, list);
    }
    const sellerIds = [...bySeller.keys()];
    const sellers = await this.prisma.seller.findMany({
      where: { id: { in: sellerIds } },
    });
    const sellerById = new Map(sellers.map((s) => [s.id, s]));
    return sellerIds.map((sellerId) => {
      const list = bySeller.get(sellerId)!;
      const seller = sellerById.get(sellerId);
      return {
        sellerId,
        sellerName: seller?.name ?? "Noma'lum sotuvchi",
        lastMessage: list[0].text,
        lastMessageAt: list[0].createdAt,
      };
    });
  }

  // ---------- Sotuvchi (seller_web) ----------

  async sellerListProducts(sellerId: string) {
    const products = await this.prisma.product.findMany({
      where: { sellerId },
      orderBy: { createdAt: 'desc' },
    });
    return products.map((p) => ({
      ...p,
      name: p.name as unknown as I18nString,
      description: p.description as unknown as I18nString | null,
      sizes: p.sizes,
    }));
  }

  async sellerCreateProduct(
    sellerId: string,
    sellerType: SellerType,
    dto: CreateProductDto,
  ) {
    if (dto.categoryId) await this.requireCategory(dto.categoryId);
    return this.prisma.product.create({
      data: {
        sellerId,
        sellerType,
        categoryId: dto.categoryId,
        name: { ...dto.name } as Prisma.InputJsonValue,
        description: dto.description
          ? ({ ...dto.description } as Prisma.InputJsonValue)
          : Prisma.JsonNull,
        price: dto.price,
        imageUrls: dto.imageUrls ?? [],
        sizes: this.normalizeSizes(dto.sizes),
        isActive: dto.isActive ?? true,
      },
    });
  }

  async sellerUpdateProduct(sellerId: string, id: string, dto: UpdateProductDto) {
    const product = await this.requireProduct(id);
    if (product.sellerId !== sellerId) {
      throw new ForbiddenException('Bu mahsulot sizga tegishli emas');
    }
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

  async sellerDeleteProduct(sellerId: string, id: string) {
    const product = await this.requireProduct(id);
    if (product.sellerId !== sellerId) {
      throw new ForbiddenException('Bu mahsulot sizga tegishli emas');
    }
    await this.prisma.product.delete({ where: { id } });
    return { ok: true };
  }

  /** Sotuvchi: o'ziga yozgan mijozlar ro'yxati + oxirgi xabar + o'qilmagan son. */
  async sellerListChatThreads(sellerId: string) {
    const messages = await this.prisma.chatMessage.findMany({
      where: { sellerId },
      orderBy: { createdAt: 'desc' },
    });
    const byCustomer = new Map<string, typeof messages>();
    for (const m of messages) {
      const list = byCustomer.get(m.customerId) ?? [];
      list.push(m);
      byCustomer.set(m.customerId, list);
    }
    return [...byCustomer.entries()].map(([customerId, list]) => ({
      customerId,
      lastMessage: list[0].text,
      lastMessageAt: list[0].createdAt,
      unseenCount: list.filter((m) => m.senderRole === 'CUSTOMER' && !m.seenAt)
        .length,
    }));
  }

  async sellerMarkChatSeen(sellerId: string, customerId: string) {
    await this.prisma.chatMessage.updateMany({
      where: { sellerId, customerId, senderRole: 'CUSTOMER', seenAt: null },
      data: { seenAt: new Date() },
    });
    return { ok: true };
  }

  async getSellerProfileRaw(sellerId: string) {
    const seller = await this.requireSeller(sellerId);
    return seller;
  }

  async updateSellerProfile(sellerId: string, dto: UpdateSellerProfileDto) {
    await this.requireSeller(sellerId);
    return this.prisma.seller.update({
      where: { id: sellerId },
      data: { ...dto },
    });
  }

  // ---------- Admin: sotuvchilar ----------

  adminListSellers(sellerType?: SellerType) {
    return this.prisma.seller.findMany({
      where: sellerType ? { sellerType } : undefined,
      orderBy: { createdAt: 'desc' },
    });
  }

  createSeller(dto: CreateSellerDto) {
    return this.prisma.seller.create({
      data: {
        name: dto.name,
        description: dto.description,
        contactPhone: dto.contactPhone,
        sellerType: dto.sellerType as SellerType,
        address: dto.address,
        lat: dto.lat,
        lng: dto.lng,
      },
    });
  }

  async updateSeller(id: string, dto: UpdateSellerDto) {
    await this.requireSeller(id);
    return this.prisma.seller.update({ where: { id }, data: { ...dto } });
  }

  async deleteSeller(id: string) {
    await this.requireSeller(id);
    await this.prisma.seller.delete({ where: { id } });
    return { ok: true };
  }

  // ---------- Admin: kategoriyalar ----------

  async listCategories(sellerType?: SellerType) {
    const categories = await this.prisma.category.findMany({
      where: sellerType ? { sellerType } : undefined,
      orderBy: { sortOrder: 'asc' },
    });
    return categories.map((c) => ({
      id: c.id,
      name: c.name as unknown as I18nString,
      sellerType: c.sellerType,
      sortOrder: c.sortOrder,
    }));
  }

  createCategory(dto: CreateCategoryDto) {
    return this.prisma.category.create({
      data: {
        name: { ...dto.name } as Prisma.InputJsonValue,
        sellerType: dto.sellerType as SellerType,
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
        "Bu kategoriyada mahsulotlar bor — avval ularni boshqa kategoriyaga o'tkazing"
      );
    }
    await this.prisma.category.delete({ where: { id } });
    return { ok: true };
  }

  // ---------- Admin: mahsulot moderatsiyasi ----------

  async adminListProducts(sellerId?: string) {
    const products = await this.prisma.product.findMany({
      where: sellerId ? { sellerId } : undefined,
      include: { seller: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return products.map((p) => ({
      ...p,
      name: p.name as unknown as I18nString,
      description: p.description as unknown as I18nString | null,
      sellerName: p.seller.name,
    }));
  }

  async adminDeleteProduct(id: string) {
    await this.requireProduct(id);
    await this.prisma.product.delete({ where: { id } });
    return { ok: true };
  }

  // ---------- yordamchilar ----------

  private async requireProduct(id: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: { seller: true },
    });
    if (!product) throw new NotFoundException('Mahsulot topilmadi');
    return product;
  }

  private async requireSeller(id: string) {
    const seller = await this.prisma.seller.findUnique({ where: { id } });
    if (!seller) throw new NotFoundException('Sotuvchi topilmadi');
    return seller;
  }

  private async requireCategory(id: string) {
    const category = await this.prisma.category.findUnique({ where: { id } });
    if (!category) throw new NotFoundException('Kategoriya topilmadi');
    return category;
  }

  /** Reyting yuqorilarni oldinga, qolganini aralashtirib — yangi sotuvchilarga ham ko'rinish beradi. */
  private mixRandomAndRating<T extends { ratingAvg: number | null }>(
    items: T[],
  ): T[] {
    const rated = items
      .filter((p) => p.ratingAvg !== null)
      .sort((a, b) => (b.ratingAvg as number) - (a.ratingAvg as number));
    const unrated = items.filter((p) => p.ratingAvg === null);
    for (let i = unrated.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [unrated[i], unrated[j]] = [unrated[j], unrated[i]];
    }
    return [...rated, ...unrated];
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
      sellerId: string;
      categoryId: string | null;
      sellerType: SellerType;
      name: unknown;
      description: unknown;
      price: number;
      imageUrls: string[];
      sizes: string[];
      ratingAvg: number | null;
      seller: {
        name: string;
        contactPhone: string;
        address: string | null;
        lat: number | null;
        lng: number | null;
      };
    },
    locale: SupportedLocale,
    near?: { lat: number; lng: number },
  ) {
    const distanceKm =
      near && p.seller.lat !== null && p.seller.lng !== null
        ? this.haversineKm(near.lat, near.lng, p.seller.lat, p.seller.lng)
        : null;
    return {
      id: p.id,
      sellerId: p.sellerId,
      categoryId: p.categoryId,
      sellerType: p.sellerType,
      name: pickLocale(p.name as I18nString, locale),
      description: p.description
        ? pickLocale(p.description as I18nString, locale)
        : null,
      price: p.price,
      imageUrls: p.imageUrls,
      sizes: p.sizes,
      ratingAvg: p.ratingAvg,
      sellerName: p.seller.name,
      sellerContactPhone: p.seller.contactPhone,
      sellerAddress: p.seller.address,
      /** Mijozgacha masofa (km, 1 xona) — faqat ?lat&lng so'ralganda. */
      distanceKm,
    };
  }

  /** Ikki nuqta orasidagi masofa (km, 1 xona aniqlikda). */
  private haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const toRad = (d: number) => (d * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
    return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 10) / 10;
  }
}
