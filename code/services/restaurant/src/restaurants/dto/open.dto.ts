import { IsBoolean } from 'class-validator';

/** Oshxona ochiq/yopiq holati. */
export class OpenDto {
  @IsBoolean()
  isOpen!: boolean;
}
