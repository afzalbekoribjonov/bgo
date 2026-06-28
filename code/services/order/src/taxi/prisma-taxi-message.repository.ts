import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ChatRole, NewTaxiMessage, TaxiMessage } from './entities';
import { TaxiMessageRepository } from './taxi-message.repository';

type Row = Record<string, unknown>;

/** PostgreSQL (order_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaTaxiMessageRepository extends TaxiMessageRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async listByTrip(tripId: string): Promise<TaxiMessage[]> {
    const rows = await this.prisma.taxiMessage.findMany({
      where: { tripId },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((m) => this.toMessage(m as Row));
  }

  countByTrip(tripId: string): Promise<number> {
    return this.prisma.taxiMessage.count({ where: { tripId } });
  }

  async create(data: NewTaxiMessage): Promise<TaxiMessage> {
    const created = await this.prisma.taxiMessage.create({
      data: {
        tripId: data.tripId,
        senderId: data.senderId,
        senderRole: data.senderRole,
        text: data.text,
      },
    });
    return this.toMessage(created as Row);
  }

  async deleteByTrip(tripId: string): Promise<void> {
    await this.prisma.taxiMessage.deleteMany({ where: { tripId } });
  }

  private toMessage(m: Row): TaxiMessage {
    return {
      id: m.id as string,
      tripId: m.tripId as string,
      senderId: m.senderId as string,
      senderRole: m.senderRole as ChatRole,
      text: m.text as string,
      createdAt: (m.createdAt as Date).toISOString(),
    };
  }
}
