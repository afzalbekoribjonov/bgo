import { IsNotEmpty, IsString } from 'class-validator';

export class DriverActionDto {
  // TODO(driver auth): JWT (driver roli) ulanganda olib tashlanadi (sub'dan olinadi).
  @IsString()
  @IsNotEmpty()
  driverId!: string;
}
