import { Component, Input } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-empty-state',
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="empty">
      <h3>{{ title }}</h3>
      <p>{{ message }}</p>
      @if (actionLabel && actionLink) {
        <a class="btn btn-primary" [routerLink]="actionLink">{{ actionLabel }}</a>
      }
    </div>
  `,
  styles: `
    .empty {
      text-align: center;
      padding: 3rem 1.25rem;
      background: var(--surface);
      border: 1px dashed var(--border);
      border-radius: var(--radius);
    }

    h3 {
      margin: 0 0 0.5rem;
      font-size: 1.25rem;
    }

    p {
      margin: 0 0 1.25rem;
      color: var(--muted);
    }
  `
})
export class EmptyStateComponent {
  @Input({ required: true }) title!: string;
  @Input({ required: true }) message!: string;
  @Input() actionLabel = '';
  @Input() actionLink = '';
}
