import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, tap } from 'rxjs';
import { API_BASE_URL } from '../constants';
import { AddToWishlistRequest, Wishlist } from '../../models/wishlist.model';

@Injectable({ providedIn: 'root' })
export class WishlistService {
  private readonly http = inject(HttpClient);
  private readonly wishlistSubject = new BehaviorSubject<Wishlist | null>(null);

  readonly wishlist$ = this.wishlistSubject.asObservable();

  loadWishlist(): Observable<Wishlist> {
    return this.http.get<Wishlist>(`${API_BASE_URL}/wishlist`).pipe(
      tap((wishlist) => this.wishlistSubject.next(wishlist))
    );
  }

  addItem(request: AddToWishlistRequest): Observable<Wishlist> {
    return this.http.post<Wishlist>(`${API_BASE_URL}/wishlist/items`, request).pipe(
      tap((wishlist) => this.wishlistSubject.next(wishlist))
    );
  }

  removeItem(productId: number): Observable<Wishlist> {
    return this.http.delete<Wishlist>(`${API_BASE_URL}/wishlist/items/${productId}`).pipe(
      tap((wishlist) => this.wishlistSubject.next(wishlist))
    );
  }

  isInWishlist(productId: number): boolean {
    return !!this.wishlistSubject.value?.items.some((item) => item.productId === productId);
  }

  resetLocalWishlist(): void {
    this.wishlistSubject.next(null);
  }
}
