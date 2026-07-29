import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import ImageKit from 'imagekit';

/**
 * Rasm yuklash (ImageKit). API kalitlari .env'da bo'lmasa `client` null
 * qoladi — upload-auth so'rovi aniq xato bilan rad etiladi, boshqa
 * hamma narsa (katalog/chat) ishlayveradi.
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

  /**
   * Client (seller_web/admin_web) to'g'ridan-to'g'ri ImageKit REST API'ga
   * yuklashi uchun kerakli hamma narsa: imzolangan parametrlar + publicKey
   * (bu maxfiy emas — ImageKit dizayni bo'yicha ochiq kalit).
   */
  uploadAuthParams(): {
    token: string;
    expire: number;
    signature: string;
    publicKey: string;
  } {
    if (!this.client || !this.publicKey) {
      throw new ServiceUnavailableException(
        'ImageKit sozlanmagan — administrator IMAGEKIT_PUBLIC_KEY/PRIVATE_KEY/URL_ENDPOINT ni .env ga kiritishi kerak',
      );
    }
    return { ...this.client.getAuthenticationParameters(), publicKey: this.publicKey };
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
