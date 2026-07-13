package com.ecommerce.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@Builder
public class RevenueSummaryResponse {
    private BigDecimal totalRevenue;
    private long successfulPaymentCount;
    private long confirmedOrderCount;
}
