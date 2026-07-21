import { HttpErrorResponse } from '@angular/common/http';
import { ApiError } from '../../models/api-error.model';

export function extractErrorMessage(error: unknown, fallback = 'Something went wrong'): string {
  if (error instanceof HttpErrorResponse) {
    const body = error.error as ApiError | string | null;
    if (body && typeof body === 'object' && 'message' in body && body.message) {
      return body.message;
    }
    if (typeof body === 'string' && body.trim()) {
      return body;
    }
    if (error.status === 0) {
      return 'Unable to reach the server. Is the backend running on port 8080?';
    }
    return error.message || fallback;
  }
  if (error instanceof Error) {
    return error.message;
  }
  return fallback;
}
