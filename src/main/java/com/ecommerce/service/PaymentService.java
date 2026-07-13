package com.ecommerce.service;

import com.ecommerce.dto.request.PaymentRequest;
import com.ecommerce.dto.response.PaymentResponse;

public interface PaymentService {
    PaymentResponse simulatePayment(Long userId, PaymentRequest request);
    PaymentResponse getByOrderNumber(Long userId, String orderNumber);
}
