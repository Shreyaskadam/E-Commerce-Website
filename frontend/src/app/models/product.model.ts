export type ProductCategory = 'ELECTRONICS' | 'CLOTHING' | 'BOOK';

export interface Product {
  id: number;
  name: string;
  description: string | null;
  category: ProductCategory;
  price: number;
  stockQuantity: number;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ProductFilter {
  name?: string;
  category?: ProductCategory | '';
  minPrice?: number | null;
  maxPrice?: number | null;
  activeOnly?: boolean;
}
