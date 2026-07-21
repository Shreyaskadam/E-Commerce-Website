# NovaMart Frontend (Angular 19)

Angular standalone SPA integrated with the Spring Boot E-Commerce API.

## Prerequisites

- Node.js 18+
- Backend running on `http://localhost:8080`

## Run

```bash
cd frontend
npm install
npm start
```

App URL: `http://localhost:4200`

Dev proxy forwards `/api/*` to `http://localhost:8080`. The app also calls the API directly at `http://localhost:8080/api` with CORS enabled on the backend.

## Features

- Signup / login with JWT persistence (`localStorage`)
- Auth interceptor + route guards
- Product catalog with search and filters
- Product details
- Cart with live updates
- Checkout (shipping form + payment simulation)
- Wishlist
- Order history / order detail
- Loading, empty, success, and error states
