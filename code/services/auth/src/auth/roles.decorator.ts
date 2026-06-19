import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

/** Endpoint uchun zarur rollar. RolesGuard bilan birga ishlatiladi. */
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);

/** Tizimdagi mavjud rollar. plan/10-auth-security.md */
export const ALLOWED_ROLES = [
  'customer',
  'driver',
  'restaurant',
  'operator',
  'admin',
  'super_admin',
] as const;
