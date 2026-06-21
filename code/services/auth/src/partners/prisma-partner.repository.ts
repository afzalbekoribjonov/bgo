import { Injectable } from '@nestjs/common';
import {
  PartnerApplication as PrismaPartner,
  PartnerStatus as PrismaStatus,
} from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  NewPartnerApplication,
  PartnerApplication,
  PartnerStatus,
  PartnerType,
} from './partner.entity';
import { PartnerRepository } from './partner.repository';

/** PostgreSQL (auth_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaPartnerRepository extends PartnerRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async create(data: NewPartnerApplication): Promise<PartnerApplication> {
    const created = await this.prisma.partnerApplication.create({
      data: {
        userId: data.userId,
        phone: data.phone,
        fullName: data.fullName,
        type: data.type,
        note: data.note,
      },
    });
    return this.toEntity(created);
  }

  async findById(id: string): Promise<PartnerApplication | null> {
    const row = await this.prisma.partnerApplication.findUnique({ where: { id } });
    return row ? this.toEntity(row) : null;
  }

  async findByUser(userId: string): Promise<PartnerApplication[]> {
    const rows = await this.prisma.partnerApplication.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.toEntity(r));
  }

  async findAll(status?: PartnerStatus): Promise<PartnerApplication[]> {
    const rows = await this.prisma.partnerApplication.findMany({
      where: status ? { status: status as PrismaStatus } : undefined,
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.toEntity(r));
  }

  async findPending(
    userId: string,
    type: PartnerType,
  ): Promise<PartnerApplication | null> {
    const row = await this.prisma.partnerApplication.findFirst({
      where: { userId, type, status: 'PENDING' },
    });
    return row ? this.toEntity(row) : null;
  }

  async updateStatus(
    id: string,
    status: PartnerStatus,
  ): Promise<PartnerApplication> {
    const updated = await this.prisma.partnerApplication.update({
      where: { id },
      data: { status: status as PrismaStatus },
    });
    return this.toEntity(updated);
  }

  private toEntity(p: PrismaPartner): PartnerApplication {
    return {
      id: p.id,
      userId: p.userId,
      phone: p.phone,
      fullName: p.fullName,
      type: p.type as PartnerType,
      note: p.note ?? undefined,
      status: p.status as PartnerStatus,
      createdAt: p.createdAt.toISOString(),
      updatedAt: p.updatedAt.toISOString(),
    };
  }
}
