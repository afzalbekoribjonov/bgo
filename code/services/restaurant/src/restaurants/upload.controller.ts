import { randomUUID } from 'crypto';
import { existsSync, mkdirSync } from 'fs';
import { writeFile } from 'fs/promises';
import { join } from 'path';
import {
  BadRequestException,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { ImageKitService } from './imagekit.service';

/** Multer memory-storage fayli (`@types/multer`siz minimal shakl). */
interface UploadedImageFile {
  buffer: Buffer;
  mimetype: string;
  originalname: string;
  size: number;
}

const EXT_BY_MIME: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
  'image/avif': '.avif',
};

const MAX_SIZE = 5 * 1024 * 1024; // 5 MB

/** Diskdagi uploads papkasi — servis ildizida, dist'dan tashqarida. */
export const UPLOADS_DIR = join(process.cwd(), 'uploads');

/**
 * Taom/menyu rasmi yuklash (oshxona egasi yoki admin). ImageKit sozlangan
 * bo'lsa — unga, aks holda lokal diskka saqlanadi va gateway orqali statik
 * ko'rsatiladi. Ikkala holatda ham javob bir xil: { url }.
 * plan/07-restaurant-app.md
 */
@Controller('restaurants/upload')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('restaurant', 'admin')
export class UploadController {
  constructor(private readonly imagekit: ImageKitService) {
    if (!existsSync(UPLOADS_DIR)) mkdirSync(UPLOADS_DIR, { recursive: true });
  }

  @Post()
  @UseInterceptors(FileInterceptor('file'))
  async upload(@UploadedFile() file?: UploadedImageFile) {
    const ext = this.validate(file);

    if (this.imagekit.isConfigured) {
      const url = await this.imagekit.uploadBuffer(
        file!.buffer,
        `restaurant-${Date.now()}${ext}`,
        '/beshariq-restaurant',
      );
      return { success: true, data: { url } };
    }

    const name = `${Date.now()}-${randomUUID()}${ext}`;
    await writeFile(join(UPLOADS_DIR, name), file!.buffer);
    const base = process.env.PUBLIC_API_URL ?? 'http://localhost:4000';
    return { success: true, data: { url: `${base}/api/v1/restaurants/uploads/${name}` } };
  }

  /** Fayl bor-yo'qligi, turi va hajmini tekshiradi; kengaytmani qaytaradi. */
  private validate(file?: UploadedImageFile): string {
    if (!file) throw new BadRequestException("Rasm fayli yuborilmadi ('file' maydoni)");
    const ext = EXT_BY_MIME[file.mimetype];
    if (!ext) {
      throw new BadRequestException('Faqat JPG/PNG/WebP/GIF/AVIF rasm yuklash mumkin');
    }
    if (file.size > MAX_SIZE) {
      throw new BadRequestException("Rasm 5 MB dan katta bo'lmasligi kerak");
    }
    return ext;
  }
}
