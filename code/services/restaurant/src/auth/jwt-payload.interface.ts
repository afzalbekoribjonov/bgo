/** Access token payload (auth servisi imzolagan). */
export interface AccessTokenPayload {
  sub: string; // user id
  phone: string;
  roles: string[];
}
