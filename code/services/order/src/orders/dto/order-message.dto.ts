import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

/** Oshxona↔haydovchi suhbat xabari. */
export class SendOrderMessageDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  text!: string;
}
