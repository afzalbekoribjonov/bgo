import { CustomerMessageEntity, NewCustomerMessage } from './customer-message.entity';

/** Mijoz xabarlari ombori (abstrakt). DriverMessage bilan bir xil naqsh. */
export abstract class CustomerMessageRepository {
  abstract createMessage(
    data: NewCustomerMessage,
  ): Promise<CustomerMessageEntity>;
  /** Mijozga tegishli xabarlar (broadcast + shaxsiy), yangi birinchi. */
  abstract listMessagesFor(
    customerId: string,
    limit: number,
  ): Promise<CustomerMessageEntity[]>;
  /** Admin tarixi — barcha yuborilganlar, yangi birinchi. */
  abstract listAllMessages(limit: number): Promise<CustomerMessageEntity[]>;
  /** `since`dan keyingi (yoki hammasi, since null bo'lsa) xabarlar soni. */
  abstract countMessagesSince(
    customerId: string,
    since: Date | null,
  ): Promise<number>;
}
