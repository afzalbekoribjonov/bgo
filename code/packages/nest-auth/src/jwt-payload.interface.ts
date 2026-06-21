/** Access token ichidagi ma'lumot (auth servisi imzolagan). */
export interface AccessTokenPayload {
  sub: string; // user id
  phone: string;
  roles: string[];
}

/** Refresh token ichidagi ma'lumot. */
export interface RefreshTokenPayload {
  sub: string;
  type: 'refresh';
}
