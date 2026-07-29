import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CustomerMessageEntity, NewCustomerMessage } from './customer-message.entity';
import { CustomerMessageRepository } from './customer-message.repository';

/** PostgreSQL (auth_db) implementatsiyasi. */
@Injectable()
export class PrismaCustomerMessageRepository extends CustomerMessageRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async createMessage(data: NewCustomerMessage): Promise<CustomerMessageEntity> {
    const row = await this.prisma.customerMessage.create({
      data: {
        customerId: data.customerId ?? null,
        title: data.title ?? null,
        body: data.body,
      },
    });
    return this.toEntity(row);
  }

  async listMessagesFor(
    customerId: string,
    limit: number,
  ): Promise<CustomerMessageEntity[]> {
    const rows = await this.prisma.customerMessage.findMany({
      where: { OR: [{ customerId: null }, { customerId }] },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    return rows.map((r) => this.toEntity(r));
  }

  async listAllMessages(limit: number): Promise<CustomerMessageEntity[]> {
    const rows = await this.prisma.customerMessage.findMany({
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    return rows.map((r) => this.toEntity(r));
  }

  async countMessagesSince(
    customerId: string,
    since: Date | null,
  ): Promise<number> {
    return this.prisma.customerMessage.count({
      where: {
        OR: [{ customerId: null }, { customerId }],
        ...(since ? { createdAt: { gt: since } } : {}),
      },
    });
  }

  private toEntity(m: {
    id: string;
    customerId: string | null;
    title: string | null;
    body: string;
    createdAt: Date;
  }): CustomerMessageEntity {
    return {
      id: m.id,
      customerId: m.customerId,
      title: m.title,
      body: m.body,
      createdAt: m.createdAt.toISOString(),
    };
  }
}
