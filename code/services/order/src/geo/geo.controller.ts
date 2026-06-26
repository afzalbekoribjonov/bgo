import { Controller, Get, Query } from '@nestjs/common';
import { GeoService } from './geo.service';

/** Ochiq geo ma'lumotlari — ilovalar uchun (hududlar, joylar, hudud tekshiruvi). */
@Controller('geo')
export class GeoController {
  constructor(private readonly geo: GeoService) {}

  /** Faol xizmat hududlari + joylar. */
  @Get('areas')
  async areas() {
    return { success: true, data: await this.geo.listActiveAreas() };
  }

  /** Faol hududlardagi yo'llar (Beshariq-maxsus xarita qatlami). */
  @Get('roads')
  async roads() {
    return { success: true, data: await this.geo.listRoads() };
  }

  /** Nuqta xizmat hududi ichidami: ?lat=..&lng=.. */
  @Get('check')
  async check(@Query('lat') lat: string, @Query('lng') lng: string) {
    const latN = Number(lat);
    const lngN = Number(lng);
    if (Number.isNaN(latN) || Number.isNaN(lngN)) {
      return { success: true, data: { inside: false } };
    }
    return { success: true, data: await this.geo.check(latN, lngN) };
  }
}
