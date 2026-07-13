package com.ecommerce.dto.response;

import com.ecommerce.enums.OrderStatus;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class OrdersByStatusResponse {
    private OrderStatus status;
    private long count;
}
