import { AsyncPipe, CurrencyPipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { CartService } from '../../core/services/cart.service';
import { OrderService } from '../../core/services/order.service';
import { PaymentService } from '../../core/services/payment.service';
import { extractErrorMessage } from '../../core/utils/error.util';
import { PaymentMethod } from '../../models/order.model';
import { AlertMessageComponent } from '../../shared/components/alert-message.component';
import { EmptyStateComponent } from '../../shared/components/empty-state.component';
import { LoadingSpinnerComponent } from '../../shared/components/loading-spinner.component';

@Component({
  selector: 'app-checkout',
  standalone: true,
  imports: [
    AsyncPipe,
    CurrencyPipe,
    ReactiveFormsModule,
    AlertMessageComponent,
    EmptyStateComponent,
    LoadingSpinnerComponent
  ],
  templateUrl: './checkout.component.html',
  styleUrl: './checkout.component.css'
})
export class CheckoutComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly cartService = inject(CartService);
  private readonly orderService = inject(OrderService);
  private readonly paymentService = inject(PaymentService);
  private readonly router = inject(Router);

  readonly cart$ = this.cartService.cart$;
  readonly paymentMethods: PaymentMethod[] = ['CARD', 'WALLET', 'CASH_ON_DELIVERY'];

  loading = true;
  submitting = false;
  errorMessage = '';
  successMessage = '';

  readonly form = this.fb.nonNullable.group({
    fullName: ['', [Validators.required, Validators.maxLength(100)]],
    phone: ['', [Validators.required, Validators.pattern(/^[0-9+\-\s]{8,20}$/)]],
    addressLine1: ['', [Validators.required, Validators.maxLength(200)]],
    addressLine2: [''],
    city: ['', [Validators.required, Validators.maxLength(100)]],
    state: ['', [Validators.required, Validators.maxLength(100)]],
    postalCode: ['', [Validators.required, Validators.maxLength(20)]],
    country: ['India', [Validators.required, Validators.maxLength(100)]],
    paymentMethod: ['CARD' as PaymentMethod, [Validators.required]],
    simulateSuccess: [true]
  });

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

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const cart = this.cartService.getCartSnapshot();
    if (!cart || cart.items.length === 0) {
      this.errorMessage = 'Your cart is empty.';
      return;
    }

    this.submitting = true;
    this.errorMessage = '';
    this.successMessage = '';

    const { paymentMethod, simulateSuccess } = this.form.getRawValue();

    this.orderService.placeOrder({ paymentMethod }).subscribe({
      next: (order) => {
        this.cartService.resetLocalCart();
        this.paymentService
          .simulatePayment({
            orderNumber: order.orderNumber,
            paymentMethod,
            simulateSuccess
          })
          .subscribe({
            next: (payment) => {
              this.submitting = false;
              this.successMessage =
                payment.status === 'SUCCESS'
                  ? `Order ${order.orderNumber} placed and payment succeeded.`
                  : `Order ${order.orderNumber} placed but payment simulation failed.`;
              void this.router.navigate(['/orders', order.orderNumber], {
                queryParams: { payment: payment.status }
              });
            },
            error: (err) => {
              this.submitting = false;
              this.errorMessage = extractErrorMessage(
                err,
                `Order ${order.orderNumber} was created, but payment simulation failed.`
              );
              void this.router.navigate(['/orders', order.orderNumber]);
            }
          });
      },
      error: (err) => {
        this.submitting = false;
        this.errorMessage = extractErrorMessage(err, 'Checkout failed');
      }
    });
  }
}
