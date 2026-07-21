package com.ecommerce.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class WishlistResponse {
    private List<WishlistItemResponse> items;
    private int totalItems;
}
