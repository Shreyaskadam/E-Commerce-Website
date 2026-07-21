export type PaymentMethod = 'CARD' | 'WALLET' | 'CASH_ON_DELIVERY';
export type PaymentStatus = 'PENDING' | 'SUCCESS' | 'FAILED';
export type OrderStatus = 'CREATED' | 'CONFIRMED' | 'CANCELLED';

export interface OrderItem {
  productId: number;
  productName: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface Order {
  id: number;
  orderNumber: string;
  items: OrderItem[];
  discountAmount: number;
  taxAmount: number;
  totalAmount: number;
  status: OrderStatus;
  paymentStatus: PaymentStatus;
  createdAt: string;
}

export interface PlaceOrderRequest {
  paymentMethod: PaymentMethod;
}

export interface ShippingAddress {
  fullName: string;
  phone: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
}
