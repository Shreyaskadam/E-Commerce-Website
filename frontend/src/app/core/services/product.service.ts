import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from '../constants';
import { Product, ProductFilter } from '../../models/product.model';

@Injectable({ providedIn: 'root' })
export class ProductService {
  private readonly http = inject(HttpClient);

  getProducts(filter: ProductFilter = {}): Observable<Product[]> {
    let params = new HttpParams();

    if (filter.name?.trim()) {
      params = params.set('name', filter.name.trim());
    }
    if (filter.category) {
      params = params.set('category', filter.category);
    }
    if (filter.minPrice != null && !Number.isNaN(Number(filter.minPrice))) {
      params = params.set('minPrice', String(filter.minPrice));
    }
    if (filter.maxPrice != null && !Number.isNaN(Number(filter.maxPrice))) {
      params = params.set('maxPrice', String(filter.maxPrice));
    }
    if (filter.activeOnly !== undefined) {
      params = params.set('activeOnly', String(filter.activeOnly));
    }

    return this.http.get<Product[]>(`${API_BASE_URL}/products`, { params });
  }

  getProductById(id: number): Observable<Product> {
    return this.http.get<Product>(`${API_BASE_URL}/products/${id}`);
  }
}
