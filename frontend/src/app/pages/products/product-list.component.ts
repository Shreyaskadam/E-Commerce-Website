import { CurrencyPipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { CartService } from '../../core/services/cart.service';
import { ProductService } from '../../core/services/product.service';
import { WishlistService } from '../../core/services/wishlist.service';
import { extractErrorMessage } from '../../core/utils/error.util';
import { Product, ProductCategory } from '../../models/product.model';
import { AlertMessageComponent } from '../../shared/components/alert-message.component';
import { EmptyStateComponent } from '../../shared/components/empty-state.component';
import { LoadingSpinnerComponent } from '../../shared/components/loading-spinner.component';

@Component({
  selector: 'app-product-list',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    RouterLink,
    CurrencyPipe,
    AlertMessageComponent,
    EmptyStateComponent,
    LoadingSpinnerComponent
  ],
  templateUrl: './product-list.component.html',
  styleUrl: './product-list.component.css'
})
export class ProductListComponent implements OnInit {
  private readonly productService = inject(ProductService);
  private readonly cartService = inject(CartService);
  private readonly wishlistService = inject(WishlistService);
  private readonly authService = inject(AuthService);
  private readonly fb = inject(FormBuilder);

  products: Product[] = [];
  loading = false;
  errorMessage = '';
  successMessage = '';
  actionProductId: number | null = null;

  readonly categories: ProductCategory[] = ['ELECTRONICS', 'CLOTHING', 'BOOK'];

  readonly filterForm = this.fb.group({
    name: [''],
    category: ['' as ProductCategory | ''],
    minPrice: [null as number | null],
    maxPrice: [null as number | null]
  });

  ngOnInit(): void {
    this.loadProducts();
  }

  loadProducts(): void {
    this.loading = true;
    this.errorMessage = '';
    const raw = this.filterForm.getRawValue();

    this.productService
      .getProducts({
        name: raw.name || undefined,
        category: raw.category || undefined,
        minPrice: raw.minPrice,
        maxPrice: raw.maxPrice,
        activeOnly: true
      })
      .subscribe({
        next: (products) => {
          this.products = products;
          this.loading = false;
        },
        error: (err) => {
          this.loading = false;
          this.errorMessage = extractErrorMessage(err, 'Failed to load products');
        }
      });
  }

  resetFilters(): void {
    this.filterForm.reset({
      name: '',
      category: '',
      minPrice: null,
      maxPrice: null
    });
    this.loadProducts();
  }

  addToCart(product: Product): void {
    if (!this.authService.isAuthenticated()) {
      this.errorMessage = 'Please log in to add items to your cart.';
      return;
    }

    this.actionProductId = product.id;
    this.errorMessage = '';
    this.successMessage = '';

    this.cartService.addItem({ productId: product.id, quantity: 1 }).subscribe({
      next: () => {
        this.actionProductId = null;
        this.successMessage = `${product.name} added to cart.`;
      },
      error: (err) => {
        this.actionProductId = null;
        this.errorMessage = extractErrorMessage(err, 'Could not add to cart');
      }
    });
  }

  toggleWishlist(product: Product): void {
    if (!this.authService.isAuthenticated()) {
      this.errorMessage = 'Please log in to manage your wishlist.';
      return;
    }

    this.actionProductId = product.id;
    this.errorMessage = '';
    this.successMessage = '';

    const inWishlist = this.wishlistService.isInWishlist(product.id);
    const request$ = inWishlist
      ? this.wishlistService.removeItem(product.id)
      : this.wishlistService.addItem({ productId: product.id });

    request$.subscribe({
      next: () => {
        this.actionProductId = null;
        this.successMessage = inWishlist
          ? `${product.name} removed from wishlist.`
          : `${product.name} saved to wishlist.`;
      },
      error: (err) => {
        this.actionProductId = null;
        this.errorMessage = extractErrorMessage(err, 'Wishlist update failed');
      }
    });
  }

  isInWishlist(productId: number): boolean {
    return this.wishlistService.isInWishlist(productId);
  }
}
