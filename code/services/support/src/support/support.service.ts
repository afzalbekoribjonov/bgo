import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import { GeminiClient } from '../ai/gemini.client';
import { OrderLookupClient } from '../ai/order-lookup.client';
import { TariffKnowledgeClient } from '../ai/tariff-knowledge.client';
import { CUSTOMER_SYSTEM_PROMPT, DRIVER_SYSTEM_PROMPT } from '../ai/prompts';
import { UserInfoClient } from '../user-client/user-info.client';
import { I18nString, SupportedLocale, pickLocale } from '@beshariq/i18n';

const SYSTEM_FALLBACK_TEXT =
  "Hozircha AI orqali javob bera olmayapman — administratorlarimiz siz bilan bog'lanadi.";

const HISTORY_LIMIT = 30;

type Role = 'CUSTOMER' | 'DRIVER';

@Injectable()
export class SupportService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly gemini: GeminiClient,
    private readonly tariffKnowledge: TariffKnowledgeClient,
    private readonly orderLookup: OrderLookupClient,
    private readonly userInfo: UserInfoClient,
  ) {}

  // ---------- FAQ (foydalanuvchi tomoni) ----------

  async listFaq(role: Role, locale: SupportedLocale) {
    const items = await this.prisma.faqItem.findMany({
      where: {
        isActive: true,
        OR: [{ roles: { isEmpty: true } }, { roles: { has: role } }],
      },
      orderBy: { sortOrder: 'asc' },
      select: { id: true, label: true },
    });
    return items.map((i) => ({
      id: i.id,
      label: pickLocale(i.label as unknown as I18nString, locale),
    }));
  }

  // ---------- Suhbatlar (foydalanuvchi tomoni) ----------

  async createConversation(
    userId: string,
    userRole: Role,
    topic: string,
    locale: SupportedLocale,
  ) {
    if (topic === 'ai') {
      const conversation = await this.prisma.supportConversation.create({
        data: { userId, userRole, topic: 'ai', topicLabel: null },
      });
      return { conversation, messages: [] };
    }

    const faq = await this.prisma.faqItem.findFirst({
      where: {
        id: topic,
        isActive: true,
        OR: [{ roles: { isEmpty: true } }, { roles: { has: userRole } }],
      },
    });
    if (!faq) throw new NotFoundException('Savol topilmadi');

    const label = pickLocale(faq.label as unknown as I18nString, locale);
    const answer = pickLocale(faq.answer as unknown as I18nString, locale);

    const conversation = await this.prisma.supportConversation.create({
      data: { userId, userRole, topic, topicLabel: label },
    });
    const [userMsg, botMsg] = await this.prisma.$transaction([
      this.prisma.supportChatMessage.create({
        data: { conversationId: conversation.id, senderRole: 'USER', text: label },
      }),
      this.prisma.supportChatMessage.create({
        data: { conversationId: conversation.id, senderRole: 'BOT', text: answer },
      }),
    ]);
    return { conversation, messages: [userMsg, botMsg] };
  }

  async listConversations(userId: string) {
    return this.prisma.supportConversation.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      take: 100,
    });
  }

  private async requireOwnConversation(userId: string, conversationId: string) {
    const conversation = await this.prisma.supportConversation.findUnique({
      where: { id: conversationId },
    });
    if (!conversation || conversation.userId !== userId) {
      throw new NotFoundException('Suhbat topilmadi');
    }
    return conversation;
  }

  async getMessages(userId: string, conversationId: string) {
    await this.requireOwnConversation(userId, conversationId);
    return this.prisma.supportChatMessage.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
    });
  }

  /** To'liq sinxron oqim: USER xabar -> (kerak bo'lsa) Gemini -> AI/SYSTEM xabar. */
  async sendMessage(userId: string, userRole: Role, conversationId: string, text: string) {
    const conversation = await this.requireOwnConversation(userId, conversationId);

    const userMessage = await this.prisma.supportChatMessage.create({
      data: { conversationId, senderRole: 'USER', text },
    });

    // Eskalatsiya qilingan suhbatda AI qayta chaqirilmaydi — inson allaqachon
    // ishlamoqda, faqat mijoz xabari saqlanadi (admin poll orqali ko'radi).
    if (conversation.status === 'ESCALATED') {
      await this.touchConversation(conversationId);
      return { userMessage, aiMessage: null };
    }

    // Admin yechgan suhbatga mijoz qayta yozsa — suhbat qayta ochiladi.
    if (conversation.status === 'RESOLVED') {
      await this.prisma.supportConversation.update({
        where: { id: conversationId },
        data: { status: 'OPEN' },
      });
    }

    const history = await this.prisma.supportChatMessage.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'desc' },
      take: HISTORY_LIMIT,
    });
    history.reverse();

    const systemPrompt =
      userRole === 'DRIVER' ? DRIVER_SYSTEM_PROMPT : CUSTOMER_SYSTEM_PROMPT;
    const knowledgeContext = await this.tariffKnowledge.getPricingContext();

    const result = await this.gemini.converse({
      systemPrompt,
      knowledgeContext,
      history: history.map((h) => ({ senderRole: h.senderRole, text: h.text })),
    });

    if (!result) {
      const aiMessage = await this.prisma.supportChatMessage.create({
        data: { conversationId, senderRole: 'SYSTEM', text: SYSTEM_FALLBACK_TEXT },
      });
      await this.prisma.supportConversation.update({
        where: { id: conversationId },
        data: { status: 'ESCALATED', updatedAt: new Date() },
      });
      return { userMessage, aiMessage };
    }

    const aiMessage = await this.prisma.supportChatMessage.create({
      data: {
        conversationId,
        senderRole: 'AI',
        text: result.reply,
        internalNote: result.reason ?? null,
      },
    });
    await this.prisma.supportConversation.update({
      where: { id: conversationId },
      data: {
        status: result.escalate ? 'ESCALATED' : 'OPEN',
        updatedAt: new Date(),
      },
    });

    if (userRole === 'DRIVER' && result.complaintSummary) {
      await this.createComplaint(userId, conversationId, result.complaintOrderNo, result.complaintSummary);
    }

    return { userMessage, aiMessage };
  }

  /**
   * Haydovchi mijoz haqida shikoyat qildi va Gemini buyurtma raqamini
   * ajratib oldi — buyurtma orqali mijozni topib (topilsa), admin panelga
   * chiqadigan CustomerComplaint yozuvini yaratadi. Har doim best-effort —
   * xato bo'lsa suhbat oqimini buzmaydi (faqat log).
   */
  private async createComplaint(
    driverUserId: string,
    conversationId: string,
    orderNoRaw: string | undefined,
    summary: string,
  ): Promise<void> {
    try {
      const publicNo = orderNoRaw ? Number(orderNoRaw.replace(/\D/g, '')) : NaN;
      let customerId: string | null = null;
      let orderType: string | null = null;
      if (Number.isFinite(publicNo) && publicNo > 0) {
        const lookup = await this.orderLookup.lookupByDriver(driverUserId, publicNo);
        if (lookup) {
          customerId = lookup.customerId;
          orderType = lookup.type;
        }
      }
      await this.prisma.customerComplaint.create({
        data: {
          driverUserId,
          conversationId,
          orderPublicNo: Number.isFinite(publicNo) && publicNo > 0 ? publicNo : null,
          orderType,
          customerId,
          summary,
        },
      });
    } catch {
      // best-effort — shikoyat yozuvi yaratilmasa ham suhbat davom etadi.
    }
  }

  private async touchConversation(id: string) {
    await this.prisma.supportConversation.update({
      where: { id },
      data: { updatedAt: new Date() },
    });
  }

  // ---------- Admin ----------

  async adminListConversations(filter: {
    status?: 'OPEN' | 'ESCALATED' | 'RESOLVED';
    role?: Role;
    page: number;
    pageSize: number;
  }) {
    const where = {
      ...(filter.status ? { status: filter.status } : {}),
      ...(filter.role ? { userRole: filter.role } : {}),
    };
    const [rows, total] = await Promise.all([
      this.prisma.supportConversation.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        skip: (filter.page - 1) * filter.pageSize,
        take: filter.pageSize,
      }),
      this.prisma.supportConversation.count({ where }),
    ]);
    const users = await this.userInfo.getUsersInfo(rows.map((c) => c.userId));
    const items = rows.map((c) => ({ ...c, userInfo: users.get(c.userId) ?? null }));
    return { items, total, page: filter.page, pageSize: filter.pageSize };
  }

  async adminGetMessages(conversationId: string) {
    const conversation = await this.prisma.supportConversation.findUnique({
      where: { id: conversationId },
    });
    if (!conversation) throw new NotFoundException('Suhbat topilmadi');
    const userInfo = await this.userInfo.getUserInfo(conversation.userId);
    const messages = await this.prisma.supportChatMessage.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
    });
    return { conversation: { ...conversation, userInfo }, messages };
  }

  async adminReply(conversationId: string, text: string) {
    const conversation = await this.prisma.supportConversation.findUnique({
      where: { id: conversationId },
    });
    if (!conversation) throw new NotFoundException('Suhbat topilmadi');
    const message = await this.prisma.supportChatMessage.create({
      data: { conversationId, senderRole: 'ADMIN', text },
    });
    await this.prisma.supportConversation.update({
      where: { id: conversationId },
      data: { status: 'RESOLVED', updatedAt: new Date() },
    });
    return message;
  }

  // ---------- Admin — Mijozlarga shikoyatlar ----------

  async adminListComplaints(status?: 'OPEN' | 'RESOLVED' | 'DISMISSED') {
    const rows = await this.prisma.customerComplaint.findMany({
      where: status ? { status } : undefined,
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
    const ids = Array.from(
      new Set(
        rows.flatMap((c) => [c.driverUserId, c.customerId]).filter((v): v is string => !!v),
      ),
    );
    const users = await this.userInfo.getUsersInfo(ids);
    return rows.map((c) => ({
      ...c,
      driverInfo: users.get(c.driverUserId) ?? null,
      customerInfo: c.customerId ? users.get(c.customerId) ?? null : null,
    }));
  }

  async setComplaintStatus(id: string, status: 'RESOLVED' | 'DISMISSED') {
    const exists = await this.prisma.customerComplaint.findUnique({ where: { id } });
    if (!exists) throw new NotFoundException('Shikoyat topilmadi');
    return this.prisma.customerComplaint.update({ where: { id }, data: { status } });
  }

  // ---------- Admin — FAQ CRUD ----------

  adminListFaq() {
    return this.prisma.faqItem.findMany({ orderBy: { sortOrder: 'asc' } });
  }

  createFaq(dto: {
    label: I18nString;
    answer: I18nString;
    roles?: Role[];
    sortOrder?: number;
  }) {
    return this.prisma.faqItem.create({
      data: {
        label: { ...dto.label } as Prisma.InputJsonValue,
        answer: { ...dto.answer } as Prisma.InputJsonValue,
        roles: dto.roles ?? [],
        sortOrder: dto.sortOrder ?? 0,
      },
    });
  }

  async updateFaq(
    id: string,
    dto: Partial<{
      label: I18nString;
      answer: I18nString;
      roles: Role[];
      sortOrder: number;
      isActive: boolean;
    }>,
  ) {
    const exists = await this.prisma.faqItem.findUnique({ where: { id } });
    if (!exists) throw new NotFoundException('Savol topilmadi');
    const { label, answer, ...rest } = dto;
    return this.prisma.faqItem.update({
      where: { id },
      data: {
        ...rest,
        ...(label ? { label: { ...label } as Prisma.InputJsonValue } : {}),
        ...(answer ? { answer: { ...answer } as Prisma.InputJsonValue } : {}),
      },
    });
  }

  async deleteFaq(id: string) {
    const exists = await this.prisma.faqItem.findUnique({ where: { id } });
    if (!exists) throw new NotFoundException('Savol topilmadi');
    await this.prisma.faqItem.delete({ where: { id } });
    return { ok: true };
  }
}
