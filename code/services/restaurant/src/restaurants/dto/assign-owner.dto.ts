import { IsNotEmpty, IsString } from 'class-validator';

export class AssignOwnerDto {
  @IsString()
  @IsNotEmpty()
  ownerUserId!: string;
}
