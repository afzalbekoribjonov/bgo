import { NewTaxiMessage, TaxiMessage } from './entities';

/** Taksi suhbat xabarlari repository interfeysi (abstrakt). */
export abstract class TaxiMessageRepository {
  abstract listByTrip(tripId: string): Promise<TaxiMessage[]>;
  abstract countByTrip(tripId: string): Promise<number>;
  abstract create(data: NewTaxiMessage): Promise<TaxiMessage>;
}
