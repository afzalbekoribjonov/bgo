import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Request } from 'express';
import { AccessTokenPayload } from '../auth/jwt-payload.interface';
import { RestaurantsService } from './restaurants.service';

/**
 * Foydalanuvchi :restaurantId egasimi yoki adminmi — tekshiradi.
 * JwtAuthGuard + RolesGuard'dan KEYIN ishlatiladi. plan/07-restaurant-app.md
 */
@Injectable()
export class RestaurantOwnerGuard implements CanActivate {
  constructor(private readonly service: RestaurantsService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context
      .switchToHttp()
      .getRequest<
        Request & { user?: AccessTokenPayload; params: Record<string, string> }
      >();
    const user = request.user;
    if (!user) throw new ForbiddenException('Ruxsat yetarli emas');
    // Admin har qanday oshxonani boshqara oladi
    if (user.roles.includes('admin')) return true;

    const restaurantId = request.params.restaurantId;
    if (!restaurantId) return true;
    const owner = await this.service.isOwner(restaurantId, user.sub);
    if (!owner) {
      throw new ForbiddenException('Bu oshxona sizga tegishli emas');
    }
    return true;
  }
}
