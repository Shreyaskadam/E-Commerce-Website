package com.ecommerce.dto.response;

import com.ecommerce.enums.ProductCategory;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Builder
public class WishlistItemResponse {
    private Long wishlistItemId;
    private Long productId;
    private String productName;
    private String description;
    private ProductCategory category;
    private BigDecimal price;
    private Integer stockQuantity;
    private boolean active;
    private LocalDateTime addedAt;
}
