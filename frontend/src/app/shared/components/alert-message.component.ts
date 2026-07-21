import { Component, Input } from '@angular/core';

export type AlertType = 'error' | 'success' | 'info';

@Component({
  selector: 'app-alert-message',
  standalone: true,
  template: `
    @if (message) {
      <div class="alert" [class]="type" role="alert">{{ message }}</div>
    }
  `,
  styles: `
    .alert {
      padding: 0.85rem 1rem;
      border-radius: var(--radius-sm);
      margin-bottom: 1rem;
      font-size: 0.95rem;
      line-height: 1.4;
    }

    .error {
      background: #fdeceb;
      color: #8a1f17;
      border: 1px solid #f5c2be;
    }

    .success {
      background: #e8f6ee;
      color: #146c43;
      border: 1px solid #b7e4c7;
    }

    .info {
      background: #eaf2fb;
      color: #1d4f91;
      border: 1px solid #bfd7f2;
    }
  `
})
export class AlertMessageComponent {
  @Input() message = '';
  @Input() type: AlertType = 'error';
}
