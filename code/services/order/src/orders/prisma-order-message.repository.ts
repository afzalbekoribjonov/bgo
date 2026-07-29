import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ChatRole, NewOrderMessage, OrderMessage } from './entities';
import { OrderMessageRepository } from './order-message.repository';

type Row = Record<string, unknown>;

/** PostgreSQL (order_db) implementatsiyasi. */
@Injectable()
export class PrismaOrderMessageRepository extends OrderMessageRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async listByOrder(orderId: string): Promise<OrderMessage[]> {
    const rows = await this.prisma.orderMessage.findMany({
      where: { orderId },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((m) => this.toMessage(m as Row));
  }

  countByOrder(orderId: string): Promise<number> {
    return this.prisma.orderMessage.count({ where: { orderId } });
  }

  async create(data: NewOrderMessage): Promise<OrderMessage> {
    const created = await this.prisma.orderMessage.create({
      data: {
        orderId: data.orderId,
        senderId: data.senderId,
        senderRole: data.senderRole,
        text: data.text,
      },
    });
    return this.toMessage(created as Row);
  }

  async deleteByOrder(orderId: string): Promise<void> {
    await this.prisma.orderMessage.deleteMany({ where: { orderId } });
  }

  private toMessage(m: Row): OrderMessage {
    return {
      id: m.id as string,
      orderId: m.orderId as string,
      senderId: m.senderId as string,
      senderRole: m.senderRole as ChatRole,
      text: m.text as string,
      createdAt: (m.createdAt as Date).toISOString(),
    };
  }
}
