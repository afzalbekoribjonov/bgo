import { Equals, IsBoolean, IsString } from 'class-validator';

export class ConsentDto {
  /** Maxfiylik siyosatiga rozilik majburiy (true bo'lishi shart). */
  @IsBoolean()
  @Equals(true, { message: 'Maxfiylik siyosatiga rozilik majburiy' })
  privacy!: boolean;

  /** Qabul qilingan siyosat versiyasi, masalan "1.0" */
  @IsString()
  version!: string;
}
