import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Request } from 'express';
import { AccessTokenPayload } from './jwt-payload.interface';

/** Controller'da @CurrentUser() bilan joriy foydalanuvchi payload'ini olish. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext): AccessTokenPayload => {
    const request = context
      .switchToHttp()
      .getRequest<Request & { user: AccessTokenPayload }>();
    return request.user;
  },
);
