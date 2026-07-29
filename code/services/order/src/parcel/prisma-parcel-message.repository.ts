import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ChatRole, NewParcelMessage, ParcelMessage } from './entities';
import { ParcelMessageRepository } from './parcel-message.repository';

type Row = Record<string, unknown>;

/** PostgreSQL (order_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaParcelMessageRepository extends ParcelMessageRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async listByParcel(parcelId: string): Promise<ParcelMessage[]> {
    const rows = await this.prisma.parcelMessage.findMany({
      where: { parcelId },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((m) => this.toMessage(m as Row));
  }

  countByParcel(parcelId: string): Promise<number> {
    return this.prisma.parcelMessage.count({ where: { parcelId } });
  }

  async create(data: NewParcelMessage): Promise<ParcelMessage> {
    const created = await this.prisma.parcelMessage.create({
      data: {
        parcelId: data.parcelId,
        senderId: data.senderId,
        senderRole: data.senderRole,
        text: data.text,
      },
    });
    return this.toMessage(created as Row);
  }

  async deleteByParcel(parcelId: string): Promise<void> {
    await this.prisma.parcelMessage.deleteMany({ where: { parcelId } });
  }

  private toMessage(m: Row): ParcelMessage {
    return {
      id: m.id as string,
      parcelId: m.parcelId as string,
      senderId: m.senderId as string,
      senderRole: m.senderRole as ChatRole,
      text: m.text as string,
      createdAt: (m.createdAt as Date).toISOString(),
    };
  }
}
