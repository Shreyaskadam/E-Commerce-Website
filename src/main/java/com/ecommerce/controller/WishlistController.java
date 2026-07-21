package com.ecommerce.controller;

import com.ecommerce.dto.request.AddToWishlistRequest;
import com.ecommerce.dto.response.WishlistResponse;
import com.ecommerce.service.WishlistService;
import com.ecommerce.util.SecurityUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/wishlist")
@RequiredArgsConstructor
public class WishlistController {

    private final WishlistService wishlistService;

    @GetMapping
    public ResponseEntity<WishlistResponse> getWishlist() {
        return ResponseEntity.ok(wishlistService.getWishlist(SecurityUtils.currentUserId()));
    }

    @PostMapping("/items")
    public ResponseEntity<WishlistResponse> addItem(@Valid @RequestBody AddToWishlistRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(wishlistService.addItem(SecurityUtils.currentUserId(), request));
    }

    @DeleteMapping("/items/{productId}")
    public ResponseEntity<WishlistResponse> removeItem(@PathVariable Long productId) {
        return ResponseEntity.ok(wishlistService.removeItem(SecurityUtils.currentUserId(), productId));
    }
}
