import { ProductCategory } from './product.model';

export interface WishlistItem {
  wishlistItemId: number;
  productId: number;
  productName: string;
  description: string | null;
  category: ProductCategory;
  price: number;
  stockQuantity: number;
  active: boolean;
  addedAt: string;
}

export interface Wishlist {
  items: WishlistItem[];
  totalItems: number;
}

export interface AddToWishlistRequest {
  productId: number;
}
