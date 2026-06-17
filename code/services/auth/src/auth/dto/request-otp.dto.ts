import { Matches } from 'class-validator';

export class RequestOtpDto {
  /** O'zbekiston formati: +998 va 9 raqam, masalan +998901234567 */
  @Matches(/^\+998\d{9}$/, {
    message: 'Telefon raqami +998XXXXXXXXX formatida bo\'lishi kerak',
  })
  phone!: string;
}
