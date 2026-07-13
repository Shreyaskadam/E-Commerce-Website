package com.ecommerce.controller;

import com.ecommerce.dto.request.PaymentRequest;
import com.ecommerce.dto.response.PaymentResponse;
import com.ecommerce.service.PaymentService;
import com.ecommerce.util.SecurityUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    @PostMapping
    public ResponseEntity<PaymentResponse> simulatePayment(@Valid @RequestBody PaymentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(paymentService.simulatePayment(SecurityUtils.currentUserId(), request));
    }

    @GetMapping("/order/{orderNumber}")
    public ResponseEntity<PaymentResponse> getByOrder(@PathVariable String orderNumber) {
        return ResponseEntity.ok(
                paymentService.getByOrderNumber(SecurityUtils.currentUserId(), orderNumber));
    }
}
