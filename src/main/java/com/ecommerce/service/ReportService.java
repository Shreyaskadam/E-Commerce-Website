package com.ecommerce.service;

import com.ecommerce.dto.response.OrdersByStatusResponse;
import com.ecommerce.dto.response.RevenueSummaryResponse;
import com.ecommerce.dto.response.TopSellingProductResponse;

import java.util.List;

public interface ReportService {
    List<TopSellingProductResponse> topSellingProducts(int limit);
    List<OrdersByStatusResponse> ordersByStatus();
    RevenueSummaryResponse revenueSummary();
}
