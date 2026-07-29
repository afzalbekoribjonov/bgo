import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import {
  DRIVER_CANCEL_REASONS,
  DriverCancelReason,
} from '../../common/cancel-reasons';

/** Haydovchi buyurtmadan voz kechadi — sabab majburiy. */
export class DriverCancelOrderDto {
  @IsIn(DRIVER_CANCEL_REASONS)
  reason!: DriverCancelReason;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}
