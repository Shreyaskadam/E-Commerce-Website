import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, tap } from 'rxjs';
import { API_BASE_URL } from '../constants';
import {
  AddToCartRequest,
  Cart,
  UpdateCartItemRequest
} from '../../models/cart.model';

@Injectable({ providedIn: 'root' })
export class CartService {
  private readonly http = inject(HttpClient);
  private readonly cartSubject = new BehaviorSubject<Cart | null>(null);

  readonly cart$ = this.cartSubject.asObservable();

  getCartSnapshot(): Cart | null {
    return this.cartSubject.value;
  }

  loadCart(): Observable<Cart> {
    return this.http.get<Cart>(`${API_BASE_URL}/cart`).pipe(
      tap((cart) => this.cartSubject.next(cart))
    );
  }

  addItem(request: AddToCartRequest): Observable<Cart> {
    return this.http.post<Cart>(`${API_BASE_URL}/cart/items`, request).pipe(
      tap((cart) => this.cartSubject.next(cart))
    );
  }

  updateItem(cartItemId: number, request: UpdateCartItemRequest): Observable<Cart> {
    return this.http.put<Cart>(`${API_BASE_URL}/cart/items/${cartItemId}`, request).pipe(
      tap((cart) => this.cartSubject.next(cart))
    );
  }

  removeItem(cartItemId: number): Observable<Cart> {
    return this.http.delete<Cart>(`${API_BASE_URL}/cart/items/${cartItemId}`).pipe(
      tap((cart) => this.cartSubject.next(cart))
    );
  }

  clearCart(): Observable<void> {
    return this.http.delete<void>(`${API_BASE_URL}/cart`).pipe(
      tap(() =>
        this.cartSubject.next({
          cartId: this.cartSubject.value?.cartId ?? 0,
          items: [],
          subtotal: 0,
          totalItems: 0
        })
      )
    );
  }

  resetLocalCart(): void {
    this.cartSubject.next({
      cartId: this.cartSubject.value?.cartId ?? 0,
      items: [],
      subtotal: 0,
      totalItems: 0
    });
  }
}
