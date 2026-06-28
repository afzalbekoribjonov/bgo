import {
  BadRequestException,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { combineEarnings } from '../common/earnings';
import { ReportPeriod } from '../common/reporting';
import { ParcelService } from '../parcel/parcel.service';
import { TaxiService } from '../taxi/taxi.service';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { DispatchService, DispatchVertical } from './dispatch.service';
import { OrdersService } from './orders.service';

/**
 * Haydovchi (kuryer) yetkazib berish boshqaruvi. plan/06-driver-app.md
 * Faqat 'driver' roli; driverId token (JWT sub) dan olinadi.
 */
@Controller('courier')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('driver')
export class CourierController {
  constructor(
    private readonly orders: OrdersService,
    private readonly taxi: TaxiService,
    private readonly parcel: ParcelService,
    private readonly dispatch: DispatchService,
  ) {}

  /** Menga hozir taklif qilingan buyurtma (yoki null). */
  @Get('offer')
  async offer(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.dispatch.getOfferFor(user.sub) };
  }

  /** Taklifni qabul qilish (vertikalga qarab). */
  @Post('offer/:id/accept')
  @HttpCode(200)
  async acceptOffer(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.acceptDispatch(id, user.sub) };
  }

  /** Vertikalga qarab tegishli servis bilan qabul qiladi. */
  private async acceptDispatch(id: string, driverId: string) {
    const offer = this.dispatch.getById(id);
    if (!offer || !this.dispatch.canAccept(driverId, id)) {
      throw new BadRequestException('Buyurtma endi mavjud emas');
    }
    const data = await this.acceptByVertical(offer.vertical, id, driverId);
    this.dispatch.clear(id);
    return data;
  }

  private acceptByVertical(
    vertical: DispatchVertical,
    id: string,
    driverId: string,
  ) {
    if (vertical === 'taxi') return this.taxi.accept(id, driverId);
    if (vertical === 'parcel') return this.parcel.accept(id, driverId);
    return this.orders.acceptDelivery(id, driverId);
  }

  /** Taklifni o'tkazib yuborish (keyingi haydovchiga). */
  @Post('offer/:id/skip')
  @HttpCode(200)
  async skipOffer(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    await this.dispatch.skip(user.sub, id);
    return { success: true, data: { ok: true } };
  }

  /** Qabul qilinmagan (pool) buyurtmalar — hammaga. */
  @Get('pool')
  async pool() {
    return { success: true, data: this.dispatch.pool() };
  }

  /** Pool'dan buyurtma olish. */
  @Post('pool/:id/accept')
  @HttpCode(200)
  async acceptPool(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.acceptDispatch(id, user.sub) };
  }

  /** Yetkazishga tayyor (READY), hali biriktirilmagan buyurtmalar. */
  @Get('available')
  async available() {
    return { success: true, data: await this.orders.listAvailableForDelivery() };
  }

  /** Haydovchining o'z buyurtmalari. */
  @Get('my-orders')
  async myOrders(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.orders.listDriverOrders(user.sub) };
  }

  /** Haydovchi statistikasi (Bugun) — ?period=today|week|month. */
  @Get('stats')
  async stats(
    @CurrentUser() user: AccessTokenPayload,
    @Query('period') period?: string,
  ) {
    const p = (['today', 'week', 'month'].includes(period ?? '')
      ? period
      : 'today') as ReportPeriod;
    return { success: true, data: await this.orders.driverStats(user.sub, p) };
  }

  /** Haydovchi daromadi — uchala vertikal (ovqat + taksi + dostavka). */
  @Get('earnings')
  async earnings(@CurrentUser() user: AccessTokenPayload) {
    const [food, taxi, parcel] = await Promise.all([
      this.orders.driverEarnings(user.sub),
      this.taxi.driverEarnings(user.sub),
      this.parcel.driverEarnings(user.sub),
    ]);
    return {
      success: true,
      data: { food, taxi, parcel, total: combineEarnings([food, taxi, parcel]) },
    };
  }

  @Post('orders/:id/accept')
  @HttpCode(200)
  async accept(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.orders.acceptDelivery(id, user.sub) };
  }

  @Post('orders/:id/pickup')
  @HttpCode(200)
  async pickup(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.orders.pickup(id, user.sub) };
  }

  @Post('orders/:id/delivered')
  @HttpCode(200)
  async delivered(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.orders.delivered(id, user.sub) };
  }
}
