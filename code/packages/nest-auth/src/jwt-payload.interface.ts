/** Access token ichidagi ma'lumot (auth servisi imzolagan). */
export interface AccessTokenPayload {
  sub: string; // user id (yoki oshxona kirishi uchun "kitchen:<restaurantId>")
  phone: string;
  roles: string[];
  restaurantId?: string; // oshxona login/parol kirishida — panel egaligi uchun
  sellerId?: string; // sotuvchi login/parol kirishida — panel egaligi uchun
  sellerType?: string; // sotuvchi turi: SHOP | CONSTRUCTION
}

/** Refresh token ichidagi ma'lumot. */
export interface RefreshTokenPayload {
  sub: string;
  type: 'refresh';
}
