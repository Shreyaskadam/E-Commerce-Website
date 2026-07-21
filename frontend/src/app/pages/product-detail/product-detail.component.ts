import { CurrencyPipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { CartService } from '../../core/services/cart.service';
import { ProductService } from '../../core/services/product.service';
import { WishlistService } from '../../core/services/wishlist.service';
import { extractErrorMessage } from '../../core/utils/error.util';
import { Product } from '../../models/product.model';
import { AlertMessageComponent } from '../../shared/components/alert-message.component';
import { LoadingSpinnerComponent } from '../../shared/components/loading-spinner.component';

@Component({
  selector: 'app-product-detail',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    RouterLink,
    CurrencyPipe,
    AlertMessageComponent,
    LoadingSpinnerComponent
  ],
  templateUrl: './product-detail.component.html',
  styleUrl: './product-detail.component.css'
})
export class ProductDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly productService = inject(ProductService);
  private readonly cartService = inject(CartService);
  private readonly wishlistService = inject(WishlistService);
  private readonly authService = inject(AuthService);
  private readonly fb = inject(FormBuilder);

  product: Product | null = null;
  loading = true;
  saving = false;
  errorMessage = '';
  successMessage = '';

  readonly quantityForm = this.fb.nonNullable.group({
    quantity: [1, [Validators.required, Validators.min(1)]]
  });

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (!id) {
      this.loading = false;
      this.errorMessage = 'Invalid product id.';
      return;
    }

    this.productService.getProductById(id).subscribe({
      next: (product) => {
        this.product = product;
        this.quantityForm.controls.quantity.setValidators([
          Validators.required,
          Validators.min(1),
          Validators.max(Math.max(product.stockQuantity, 1))
        ]);
        this.quantityForm.controls.quantity.updateValueAndValidity();
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.errorMessage = extractErrorMessage(err, 'Product not found');
      }
    });
  }

  addToCart(): void {
    if (!this.product || this.quantityForm.invalid) {
      this.quantityForm.markAllAsTouched();
      return;
    }
    if (!this.authService.isAuthenticated()) {
      this.errorMessage = 'Please log in to add items to your cart.';
      return;
    }

    this.saving = true;
    this.errorMessage = '';
    this.successMessage = '';

    this.cartService
      .addItem({
        productId: this.product.id,
        quantity: this.quantityForm.controls.quantity.value
      })
      .subscribe({
        next: () => {
          this.saving = false;
          this.successMessage = 'Added to cart.';
        },
        error: (err) => {
          this.saving = false;
          this.errorMessage = extractErrorMessage(err, 'Could not add to cart');
        }
      });
  }

  toggleWishlist(): void {
    if (!this.product) {
      return;
    }
    if (!this.authService.isAuthenticated()) {
      this.errorMessage = 'Please log in to manage your wishlist.';
      return;
    }

    this.saving = true;
    this.errorMessage = '';
    this.successMessage = '';

    const inWishlist = this.wishlistService.isInWishlist(this.product.id);
    const request$ = inWishlist
      ? this.wishlistService.removeItem(this.product.id)
      : this.wishlistService.addItem({ productId: this.product.id });

    request$.subscribe({
      next: () => {
        this.saving = false;
        this.successMessage = inWishlist ? 'Removed from wishlist.' : 'Saved to wishlist.';
      },
      error: (err) => {
        this.saving = false;
        this.errorMessage = extractErrorMessage(err, 'Wishlist update failed');
      }
    });
  }

  get inWishlist(): boolean {
    return this.product ? this.wishlistService.isInWishlist(this.product.id) : false;
  }
}
