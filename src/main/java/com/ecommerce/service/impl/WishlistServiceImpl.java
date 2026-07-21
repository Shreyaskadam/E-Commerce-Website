package com.ecommerce.service.impl;

import com.ecommerce.dto.request.AddToWishlistRequest;
import com.ecommerce.dto.response.WishlistItemResponse;
import com.ecommerce.dto.response.WishlistResponse;
import com.ecommerce.entity.Product;
import com.ecommerce.entity.User;
import com.ecommerce.entity.WishlistItem;
import com.ecommerce.exception.InvalidRequestException;
import com.ecommerce.exception.ProductNotFoundException;
import com.ecommerce.exception.UserNotFoundException;
import com.ecommerce.repository.ProductRepository;
import com.ecommerce.repository.UserRepository;
import com.ecommerce.repository.WishlistItemRepository;
import com.ecommerce.service.WishlistService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class WishlistServiceImpl implements WishlistService {

    private final WishlistItemRepository wishlistItemRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public WishlistResponse getWishlist(Long userId) {
        return toResponse(wishlistItemRepository.findByUserIdWithProduct(userId));
    }

    @Override
    @Transactional
    public WishlistResponse addItem(Long userId, AddToWishlistRequest request) {
        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ProductNotFoundException(
                        "Product not found with id: " + request.getProductId()));

        if (!product.isActive()) {
            throw new InvalidRequestException("Inactive products cannot be added to the wishlist");
        }

        if (wishlistItemRepository.existsByUserIdAndProductId(userId, product.getId())) {
            return getWishlist(userId);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with id: " + userId));

        WishlistItem item = WishlistItem.builder()
                .user(user)
                .product(product)
                .build();
        wishlistItemRepository.save(item);

        return getWishlist(userId);
    }

    @Override
    @Transactional
    public WishlistResponse removeItem(Long userId, Long productId) {
        WishlistItem item = wishlistItemRepository.findByUserIdAndProductId(userId, productId)
                .orElseThrow(() -> new ProductNotFoundException(
                        "Product not found in wishlist: " + productId));
        wishlistItemRepository.delete(item);
        return getWishlist(userId);
    }

    private WishlistResponse toResponse(List<WishlistItem> items) {
        List<WishlistItemResponse> responses = items.stream()
                .map(this::toItemResponse)
                .toList();
        return WishlistResponse.builder()
                .items(responses)
                .totalItems(responses.size())
                .build();
    }

    private WishlistItemResponse toItemResponse(WishlistItem item) {
        Product product = item.getProduct();
        return WishlistItemResponse.builder()
                .wishlistItemId(item.getId())
                .productId(product.getId())
                .productName(product.getName())
                .description(product.getDescription())
                .category(product.getCategory())
                .price(product.getPrice())
                .stockQuantity(product.getStockQuantity())
                .active(product.isActive())
                .addedAt(item.getCreatedAt())
                .build();
    }
}
