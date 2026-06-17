/** Access token ichidagi ma'lumot. */
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
