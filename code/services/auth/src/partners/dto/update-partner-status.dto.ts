import { IsIn } from 'class-validator';

export class UpdatePartnerStatusDto {
  @IsIn(['APPROVED', 'REJECTED'])
  status!: 'APPROVED' | 'REJECTED';
}
