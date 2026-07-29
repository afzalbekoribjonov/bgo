import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateConversationDto {
  /** FaqItem.id yoki 'ai' ("Savolim bor" — erkin suhbat). */
  @IsString()
  @IsNotEmpty()
  topic!: string;
}

export class SendMessageDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  text!: string;
}
