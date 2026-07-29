import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Haydovchi/kuryer safar davomida GPS ping'lardan haqiqatda bosib o'tgan
 * masofani jamlaydi (taxi/parcel/food) — faqat ko'rsatish uchun, narxga
 * ta'sir qilmaydi. Bir vaqtning o'zida haydovchining faqat bitta "kuzatiladigan"
 * faol safari bo'ladi (taxi IN_PROGRESS | parcel IN_TRANSIT | food PICKED_UP),
 * shu sabab ketma-ket 3 ta yengil (indekslangan) so'rov yetarli.
 */
@Injectable()
export class TripDistanceTracker {
  private readonly logger = new Logger(TripDistanceTracker.name);

  constructor(private readonly prisma: PrismaService) {}

  async accumulate(driverId: string, deltaKm: number): Promise<void> {
    try {
      const taxi = await this.prisma.taxiTrip.updateMany({
        where: { driverId, status: 'IN_PROGRESS' },
        data: { actualDistanceKm: { increment: deltaKm } },
      });
      if (taxi.count > 0) return;

      const parcel = await this.prisma.parcelDelivery.updateMany({
        where: { driverId, status: 'IN_TRANSIT' },
        data: { actualDistanceKm: { increment: deltaKm } },
      });
      if (parcel.count > 0) return;

      await this.prisma.order.updateMany({
        where: { driverId, status: 'PICKED_UP' },
        data: { actualDistanceKm: { increment: deltaKm } },
      });
    } catch (e) {
      this.logger.warn(`Masofa jamlashda xato: ${(e as Error).message}`);
    }
  }
}
