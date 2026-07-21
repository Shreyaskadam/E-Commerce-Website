import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from '../constants';
import { Order, PlaceOrderRequest } from '../../models/order.model';

@Injectable({ providedIn: 'root' })
export class OrderService {
  private readonly http = inject(HttpClient);

  placeOrder(request: PlaceOrderRequest): Observable<Order> {
    return this.http.post<Order>(`${API_BASE_URL}/orders`, request);
  }

  getOrders(): Observable<Order[]> {
    return this.http.get<Order[]>(`${API_BASE_URL}/orders`);
  }

  getOrderByNumber(orderNumber: string): Observable<Order> {
    return this.http.get<Order>(`${API_BASE_URL}/orders/${orderNumber}`);
  }
}
