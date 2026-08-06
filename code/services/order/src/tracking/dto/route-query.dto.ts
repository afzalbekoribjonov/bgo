import { Type } from 'class-transformer';
import { IsNumber, Max, Min } from 'class-validator';

/**
 * Navigatsiya marshruti so'rovi (haydovchi ilovasi uchun).
 * MUHIM: query parametrlari doim matn bo'lib keladi — global
 * ValidationPipe'ning `transform: true`si O'ZI raqamga aylantirmaydi,
 * shuning uchun har bir maydonga `@Type(() => Number)` SHART.
 */
export class RouteQueryDto {
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  fromLat!: number;

  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  fromLng!: number;

  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  toLat!: number;

  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  toLng!: number;
}
