import { AsyncPipe, CurrencyPipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CartService } from '../../core/services/cart.service';
import { extractErrorMessage } from '../../core/utils/error.util';
import { CartItem } from '../../models/cart.model';
import { AlertMessageComponent } from '../../shared/components/alert-message.component';
import { EmptyStateComponent } from '../../shared/components/empty-state.component';
import { LoadingSpinnerComponent } from '../../shared/components/loading-spinner.component';

@Component({
  selector: 'app-cart',
  standalone: true,
  imports: [
    AsyncPipe,
    CurrencyPipe,
    RouterLink,
    AlertMessageComponent,
    EmptyStateComponent,
    LoadingSpinnerComponent
  ],
  templateUrl: './cart.component.html',
  styleUrl: './cart.component.css'
})
export class CartComponent implements OnInit {
  private readonly cartService = inject(CartService);

  readonly cart$ = this.cartService.cart$;
  loading = true;
  updatingItemId: number | null = null;
  errorMessage = '';
  successMessage = '';

  ngOnInit(): void {
    this.cartService.loadCart().subscribe({
      next: () => {
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.errorMessage = extractErrorMessage(err, 'Failed to load cart');
      }
    });
  }

  increase(item: CartItem): void {
    this.updateQuantity(item, item.quantity + 1);
  }

  decrease(item: CartItem): void {
    if (item.quantity <= 1) {
      this.remove(item);
      return;
    }
    this.updateQuantity(item, item.quantity - 1);
  }

  updateQuantity(item: CartItem, quantity: number): void {
    this.updatingItemId = item.cartItemId;
    this.errorMessage = '';
    this.successMessage = '';

    this.cartService.updateItem(item.cartItemId, { quantity }).subscribe({
      next: () => {
        this.updatingItemId = null;
        this.successMessage = 'Cart updated.';
      },
      error: (err) => {
        this.updatingItemId = null;
        this.errorMessage = extractErrorMessage(err, 'Could not update cart item');
      }
    });
  }

  remove(item: CartItem): void {
    this.updatingItemId = item.cartItemId;
    this.errorMessage = '';
    this.successMessage = '';

    this.cartService.removeItem(item.cartItemId).subscribe({
      next: () => {
        this.updatingItemId = null;
        this.successMessage = 'Item removed from cart.';
      },
      error: (err) => {
        this.updatingItemId = null;
        this.errorMessage = extractErrorMessage(err, 'Could not remove item');
      }
    });
  }

  clear(): void {
    this.errorMessage = '';
    this.successMessage = '';
    this.cartService.clearCart().subscribe({
      next: () => {
        this.successMessage = 'Cart cleared.';
      },
      error: (err) => {
        this.errorMessage = extractErrorMessage(err, 'Could not clear cart');
      }
    });
  }
}
