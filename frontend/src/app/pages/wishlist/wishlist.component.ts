import { AsyncPipe, CurrencyPipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CartService } from '../../core/services/cart.service';
import { WishlistService } from '../../core/services/wishlist.service';
import { extractErrorMessage } from '../../core/utils/error.util';
import { WishlistItem } from '../../models/wishlist.model';
import { AlertMessageComponent } from '../../shared/components/alert-message.component';
import { EmptyStateComponent } from '../../shared/components/empty-state.component';
import { LoadingSpinnerComponent } from '../../shared/components/loading-spinner.component';

@Component({
  selector: 'app-wishlist',
  standalone: true,
  imports: [
    AsyncPipe,
    CurrencyPipe,
    RouterLink,
    AlertMessageComponent,
    EmptyStateComponent,
    LoadingSpinnerComponent
  ],
  templateUrl: './wishlist.component.html',
  styleUrl: './wishlist.component.css'
})
export class WishlistComponent implements OnInit {
  private readonly wishlistService = inject(WishlistService);
  private readonly cartService = inject(CartService);

  readonly wishlist$ = this.wishlistService.wishlist$;
  loading = true;
  actionProductId: number | null = null;
  errorMessage = '';
  successMessage = '';

  ngOnInit(): void {
    this.wishlistService.loadWishlist().subscribe({
      next: () => {
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.errorMessage = extractErrorMessage(err, 'Failed to load wishlist');
      }
    });
  }

  remove(item: WishlistItem): void {
    this.actionProductId = item.productId;
    this.errorMessage = '';
    this.successMessage = '';

    this.wishlistService.removeItem(item.productId).subscribe({
      next: () => {
        this.actionProductId = null;
        this.successMessage = `${item.productName} removed from wishlist.`;
      },
      error: (err) => {
        this.actionProductId = null;
        this.errorMessage = extractErrorMessage(err, 'Could not remove wishlist item');
      }
    });
  }

  moveToCart(item: WishlistItem): void {
    this.actionProductId = item.productId;
    this.errorMessage = '';
    this.successMessage = '';

    this.cartService.addItem({ productId: item.productId, quantity: 1 }).subscribe({
      next: () => {
        this.wishlistService.removeItem(item.productId).subscribe({
          next: () => {
            this.actionProductId = null;
            this.successMessage = `${item.productName} moved to cart.`;
          },
          error: (err) => {
            this.actionProductId = null;
            this.errorMessage = extractErrorMessage(err, 'Added to cart, but wishlist cleanup failed');
          }
        });
      },
      error: (err) => {
        this.actionProductId = null;
        this.errorMessage = extractErrorMessage(err, 'Could not add to cart');
      }
    });
  }
}
