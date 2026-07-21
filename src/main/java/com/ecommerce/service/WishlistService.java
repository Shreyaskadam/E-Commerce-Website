package com.ecommerce.service;

import com.ecommerce.dto.request.AddToWishlistRequest;
import com.ecommerce.dto.response.WishlistResponse;

public interface WishlistService {

    WishlistResponse getWishlist(Long userId);

    WishlistResponse addItem(Long userId, AddToWishlistRequest request);

    WishlistResponse removeItem(Long userId, Long productId);
}
