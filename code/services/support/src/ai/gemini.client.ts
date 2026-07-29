import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI, Type } from '@google/genai';

export interface ConverseHistoryItem {
  /** 'USER' bo'lsa Gemini uchun 'user', qolgan barcha rollar 'model'. */
  senderRole: 'USER' | 'BOT' | 'AI' | 'ADMIN' | 'SYSTEM';
  text: string;
}

export interface ConverseResult {
  reply: string;
  escalate: boolean;
  reason?: string;
  /** Faqat DRIVER rolida: haydovchi mijoz haqida shikoyat qilsa va buyurtma
   * raqamini aytsa — o'sha raqam (matn holida, masalan "42"). */
  complaintOrderNo?: string;
  /** Faqat DRIVER rolida: shikoyat aniqlansa — bir gaplik qisqa xulosa. */
  complaintSummary?: string;
}

/**
 * Gemini bilan bir martalik, JSON-mode structured-output chaqiruv.
 * UserInfoClient bilan bir xil "thin client, hech qachon throw qilmaydi"
 * naqshi — xato yoki sozlanmagan bo'lsa `null` qaytaradi, suhbat oqimi
 * har doim SYSTEM zaxira xabariga tushib eskalatsiya qiladi.
 */
@Injectable()
export class GeminiClient {
  private readonly logger = new Logger(GeminiClient.name);
  private readonly apiKey?: string;
  private readonly model: string;
  private client?: GoogleGenAI;

  constructor(config: ConfigService) {
    this.apiKey = config.get<string>('GEMINI_API_KEY');
    this.model = config.get<string>('GEMINI_MODEL') ?? 'gemini-2.5-flash';
  }

  get isConfigured(): boolean {
    return !!this.apiKey;
  }

  private getClient(): GoogleGenAI {
    if (!this.client) this.client = new GoogleGenAI({ apiKey: this.apiKey });
    return this.client;
  }

  async converse(params: {
    systemPrompt: string;
    knowledgeContext: string;
    history: ConverseHistoryItem[];
  }): Promise<ConverseResult | null> {
    if (!this.isConfigured) return null;
    try {
      const systemInstruction = `${params.systemPrompt}\n\n--- JORIY NARX/MA'LUMOT ---\n${params.knowledgeContext}`;
      const contents = params.history.map((h) => ({
        role: h.senderRole === 'USER' ? ('user' as const) : ('model' as const),
        parts: [{ text: h.text }],
      }));

      const response = await this.getClient().models.generateContent({
        model: this.model,
        contents,
        config: {
          systemInstruction,
          responseMimeType: 'application/json',
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              reply: { type: Type.STRING },
              escalate: { type: Type.BOOLEAN },
              reason: { type: Type.STRING },
              complaintOrderNo: { type: Type.STRING },
              complaintSummary: { type: Type.STRING },
            },
            required: ['reply', 'escalate'],
          },
        },
      });

      const raw = response.text;
      if (!raw) return null;
      const parsed = JSON.parse(raw) as Partial<ConverseResult>;
      if (typeof parsed.reply !== 'string') return null;
      return {
        reply: parsed.reply,
        escalate: !!parsed.escalate,
        reason: typeof parsed.reason === 'string' ? parsed.reason : undefined,
        complaintOrderNo:
          typeof parsed.complaintOrderNo === 'string' ? parsed.complaintOrderNo : undefined,
        complaintSummary:
          typeof parsed.complaintSummary === 'string' ? parsed.complaintSummary : undefined,
      };
    } catch (err) {
      this.logger.warn(`Gemini so'rovi muvaffaqiyatsiz: ${(err as Error).message}`);
      return null;
    }
  }
}
