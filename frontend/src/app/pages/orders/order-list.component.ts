import { CurrencyPipe, DatePipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { OrderService } from '../../core/services/order.service';
import { extractErrorMessage } from '../../core/utils/error.util';
import { Order } from '../../models/order.model';
import { AlertMessageComponent } from '../../shared/components/alert-message.component';
import { EmptyStateComponent } from '../../shared/components/empty-state.component';
import { LoadingSpinnerComponent } from '../../shared/components/loading-spinner.component';

@Component({
  selector: 'app-order-list',
  standalone: true,
  imports: [
    CurrencyPipe,
    DatePipe,
    RouterLink,
    AlertMessageComponent,
    EmptyStateComponent,
    LoadingSpinnerComponent
  ],
  templateUrl: './order-list.component.html',
  styleUrl: './order-list.component.css'
})
export class OrderListComponent implements OnInit {
  private readonly orderService = inject(OrderService);

  orders: Order[] = [];
  loading = true;
  errorMessage = '';

  ngOnInit(): void {
    this.orderService.getOrders().subscribe({
      next: (orders) => {
        this.orders = orders;
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.errorMessage = extractErrorMessage(err, 'Failed to load orders');
      }
    });
  }
}
