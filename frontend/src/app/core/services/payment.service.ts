import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from '../constants';
import { Payment, PaymentRequest } from '../../models/payment.model';

@Injectable({ providedIn: 'root' })
export class PaymentService {
  private readonly http = inject(HttpClient);

  simulatePayment(request: PaymentRequest): Observable<Payment> {
    return this.http.post<Payment>(`${API_BASE_URL}/payments`, request);
  }

  getPaymentByOrderNumber(orderNumber: string): Observable<Payment> {
    return this.http.get<Payment>(`${API_BASE_URL}/payments/order/${orderNumber}`);
  }
}
