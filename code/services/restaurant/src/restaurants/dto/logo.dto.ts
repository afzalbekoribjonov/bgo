import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

/** Oshxona logotipi (profil rasmi) — yuklangan rasm URL'i. */
export class UpdateLogoDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  logoUrl!: string;
}
