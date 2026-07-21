import { CurrencyPipe, DatePipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { OrderService } from '../../core/services/order.service';
import { PaymentService } from '../../core/services/payment.service';
import { extractErrorMessage } from '../../core/utils/error.util';
import { Order } from '../../models/order.model';
import { Payment } from '../../models/payment.model';
import { AlertMessageComponent } from '../../shared/components/alert-message.component';
import { LoadingSpinnerComponent } from '../../shared/components/loading-spinner.component';

@Component({
  selector: 'app-order-detail',
  standalone: true,
  imports: [
    CurrencyPipe,
    DatePipe,
    RouterLink,
    AlertMessageComponent,
    LoadingSpinnerComponent
  ],
  templateUrl: './order-detail.component.html',
  styleUrl: './order-detail.component.css'
})
export class OrderDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly orderService = inject(OrderService);
  private readonly paymentService = inject(PaymentService);

  order: Order | null = null;
  payment: Payment | null = null;
  loading = true;
  errorMessage = '';
  infoMessage = '';

  ngOnInit(): void {
    const orderNumber = this.route.snapshot.paramMap.get('orderNumber');
    const paymentStatus = this.route.snapshot.queryParamMap.get('payment');

    if (paymentStatus === 'SUCCESS') {
      this.infoMessage = 'Payment simulation completed successfully.';
    } else if (paymentStatus === 'FAILED') {
      this.infoMessage = 'Payment simulation failed for this order.';
    }

    if (!orderNumber) {
      this.loading = false;
      this.errorMessage = 'Invalid order number.';
      return;
    }

    this.orderService.getOrderByNumber(orderNumber).subscribe({
      next: (order) => {
        this.order = order;
        this.paymentService.getPaymentByOrderNumber(orderNumber).subscribe({
          next: (payment) => {
            this.payment = payment;
            this.loading = false;
          },
          error: () => {
            this.loading = false;
          }
        });
      },
      error: (err) => {
        this.loading = false;
        this.errorMessage = extractErrorMessage(err, 'Order not found');
      }
    });
  }
}
