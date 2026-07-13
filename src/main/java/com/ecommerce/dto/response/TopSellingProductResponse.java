package com.ecommerce.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TopSellingProductResponse {
    private Long productId;
    private String productName;
    private Long totalQuantitySold;
}
