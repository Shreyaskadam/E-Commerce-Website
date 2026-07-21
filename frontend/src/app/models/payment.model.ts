import { PaymentMethod, PaymentStatus } from './order.model';

export interface PaymentRequest {
  orderNumber: string;
  paymentMethod: PaymentMethod;
  simulateSuccess?: boolean;
}

export interface Payment {
  id: number;
  paymentReference: string;
  orderNumber: string;
  amount: number;
  paymentMethod: PaymentMethod;
  status: PaymentStatus;
  createdAt: string;
}
