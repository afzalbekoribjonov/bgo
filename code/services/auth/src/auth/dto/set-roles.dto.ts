import { ArrayNotEmpty, IsArray, IsIn } from 'class-validator';
import { ALLOWED_ROLES } from '@beshariq/nest-auth';

export class SetRolesDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsIn(ALLOWED_ROLES as unknown as string[], { each: true })
  roles!: string[];
}
