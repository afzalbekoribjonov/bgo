import { IsNumber, IsOptional, Max, Min } from 'class-validator';

/** Haydovchi joylashuvini yangilash (jonli kuzatuv). */
export class PingLocationDto {
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  lng!: number;

  /** Harakat yo'nalishi (gradus, 0-360) — ixtiyoriy. */
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(360)
  heading?: number;
}
