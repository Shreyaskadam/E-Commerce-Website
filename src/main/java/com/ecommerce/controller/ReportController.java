package com.ecommerce.controller;

import com.ecommerce.dto.response.OrdersByStatusResponse;
import com.ecommerce.dto.response.RevenueSummaryResponse;
import com.ecommerce.dto.response.TopSellingProductResponse;
import com.ecommerce.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class ReportController {

    private final ReportService reportService;

    @GetMapping("/top-selling-products")
    public ResponseEntity<List<TopSellingProductResponse>> topSelling(
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(reportService.topSellingProducts(limit));
    }

    @GetMapping("/orders-by-status")
    public ResponseEntity<List<OrdersByStatusResponse>> ordersByStatus() {
        return ResponseEntity.ok(reportService.ordersByStatus());
    }

    @GetMapping("/revenue-summary")
    public ResponseEntity<RevenueSummaryResponse> revenueSummary() {
        return ResponseEntity.ok(reportService.revenueSummary());
    }
}
