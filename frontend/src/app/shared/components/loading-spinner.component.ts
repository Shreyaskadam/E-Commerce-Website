import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-loading-spinner',
  standalone: true,
  template: `
    <div class="spinner-wrap" role="status" aria-live="polite">
      <div class="spinner"></div>
      @if (message) {
        <p>{{ message }}</p>
      }
    </div>
  `,
  styles: `
    .spinner-wrap {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 0.75rem;
      padding: 2.5rem 1rem;
      color: var(--muted);
    }

    .spinner {
      width: 2.25rem;
      height: 2.25rem;
      border: 3px solid #d7e0ea;
      border-top-color: var(--accent);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    @keyframes spin {
      to {
        transform: rotate(360deg);
      }
    }
  `
})
export class LoadingSpinnerComponent {
  @Input() message = 'Loading...';
}
