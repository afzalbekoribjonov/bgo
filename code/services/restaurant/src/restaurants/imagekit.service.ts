import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import ImageKit from 'imagekit';

/**
 * Rasm yuklash (ImageKit). API kalitlari .env'da bo'lmasa `client` null
 * qoladi — upload lokal diskka zaxiralanadi (boshqa hamma narsa ishlayveradi).
 */
@Injectable()
export class ImageKitService {
  private readonly client: ImageKit | null;
  private readonly publicKey?: string;

  constructor(config: ConfigService) {
    const publicKey = config.get<string>('IMAGEKIT_PUBLIC_KEY');
    const privateKey = config.get<string>('IMAGEKIT_PRIVATE_KEY');
    const urlEndpoint = config.get<string>('IMAGEKIT_URL_ENDPOINT');
    this.publicKey = publicKey;
    this.client =
      publicKey && privateKey && urlEndpoint
        ? new ImageKit({ publicKey, privateKey, urlEndpoint })
        : null;
  }

  get isConfigured(): boolean {
    return this.client !== null;
  }

  /** Server tomonda buffer'ni ImageKit'ga yuklaydi va CDN URL qaytaradi. */
  async uploadBuffer(buffer: Buffer, fileName: string, folder: string): Promise<string> {
    if (!this.client) {
      throw new ServiceUnavailableException('ImageKit sozlanmagan');
    }
    const res = await this.client.upload({ file: buffer, fileName, folder });
    return res.url;
  }
}
