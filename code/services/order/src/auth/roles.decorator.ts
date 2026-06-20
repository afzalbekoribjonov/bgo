import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

/** Endpoint uchun zarur rollar. RolesGuard bilan birga ishlatiladi. */
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);
