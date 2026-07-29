import { NewOrderMessage, OrderMessage } from './entities';

/** Ovqat buyurtmasi suhbat xabarlari repository interfeysi (oshxona↔haydovchi). */
export abstract class OrderMessageRepository {
  abstract listByOrder(orderId: string): Promise<OrderMessage[]>;
  abstract countByOrder(orderId: string): Promise<number>;
  abstract create(data: NewOrderMessage): Promise<OrderMessage>;
  abstract deleteByOrder(orderId: string): Promise<void>;
}
