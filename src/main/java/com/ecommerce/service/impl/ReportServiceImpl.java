package com.ecommerce.service.impl;

import com.ecommerce.dto.response.OrdersByStatusResponse;
import com.ecommerce.dto.response.RevenueSummaryResponse;
import com.ecommerce.dto.response.TopSellingProductResponse;
import com.ecommerce.enums.OrderStatus;
import com.ecommerce.enums.PaymentStatus;
import com.ecommerce.repository.OrderItemRepository;
import com.ecommerce.repository.OrderRepository;
import com.ecommerce.repository.PaymentRepository;
import com.ecommerce.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReportServiceImpl implements ReportService {

    private final OrderItemRepository orderItemRepository;
    private final OrderRepository orderRepository;
    private final PaymentRepository paymentRepository;

    @Override
    @Transactional(readOnly = true)
    public List<TopSellingProductResponse> topSellingProducts(int limit) {
        int pageSize = Math.max(1, Math.min(limit, 50));
        return orderItemRepository.findTopSellingProducts(PageRequest.of(0, pageSize)).stream()
                .map(row -> TopSellingProductResponse.builder()
                        .productId((Long) row[0])
                        .productName((String) row[1])
                        .totalQuantitySold((Long) row[2])
                        .build())
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<OrdersByStatusResponse> ordersByStatus() {
        Map<OrderStatus, Long> counts = orderRepository.countOrdersByStatus().stream()
                .collect(Collectors.toMap(
                        row -> (OrderStatus) row[0],
                        row -> (Long) row[1]));

        // Stream API: ensure all statuses appear, including zero counts
        return Arrays.stream(OrderStatus.values())
                .map(status -> OrdersByStatusResponse.builder()
                        .status(status)
                        .count(counts.getOrDefault(status, 0L))
                        .build())
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public RevenueSummaryResponse revenueSummary() {
        BigDecimal revenue = paymentRepository.sumSuccessfulPaymentAmount();
        if (revenue == null) {
            revenue = BigDecimal.ZERO;
        }
        return RevenueSummaryResponse.builder()
                .totalRevenue(revenue)
                .successfulPaymentCount(paymentRepository.countByStatus(PaymentStatus.SUCCESS))
                .confirmedOrderCount(orderRepository.countByStatus(OrderStatus.CONFIRMED))
                .build();
    }
}
