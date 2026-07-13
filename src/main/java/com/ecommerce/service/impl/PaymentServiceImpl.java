package com.ecommerce.service.impl;

import com.ecommerce.dto.request.PaymentRequest;
import com.ecommerce.dto.response.PaymentResponse;
import com.ecommerce.entity.Order;
import com.ecommerce.entity.Payment;
import com.ecommerce.enums.OrderStatus;
import com.ecommerce.enums.PaymentStatus;
import com.ecommerce.exception.OrderNotFoundException;
import com.ecommerce.exception.PaymentException;
import com.ecommerce.exception.UnauthorizedAccessException;
import com.ecommerce.mapper.EntityMapper;
import com.ecommerce.repository.OrderRepository;
import com.ecommerce.repository.PaymentRepository;
import com.ecommerce.service.PaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PaymentServiceImpl implements PaymentService {

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final EntityMapper entityMapper;

    @Override
    @Transactional
    public PaymentResponse simulatePayment(Long userId, PaymentRequest request) {
        Order order = orderRepository.findByOrderNumberWithItems(request.getOrderNumber())
                .orElseThrow(() -> new OrderNotFoundException(
                        "Order not found: " + request.getOrderNumber()));

        if (!order.getUser().getId().equals(userId)) {
            throw new UnauthorizedAccessException("You are not allowed to pay for this order");
        }

        if (paymentRepository.existsByOrderIdAndStatus(order.getId(), PaymentStatus.SUCCESS)) {
            throw new PaymentException("Order already has a successful payment");
        }

        Payment payment = order.getPayment();
        if (payment == null) {
            throw new PaymentException("No payment record found for this order");
        }

        if (payment.getStatus() == PaymentStatus.SUCCESS) {
            throw new PaymentException("Payment already completed successfully");
        }

        boolean success = request.getSimulateSuccess() == null || request.getSimulateSuccess();
        payment.setPaymentMethod(request.getPaymentMethod());

        if (success) {
            payment.setStatus(PaymentStatus.SUCCESS);
            order.setPaymentStatus(PaymentStatus.SUCCESS);
            order.setStatus(OrderStatus.CONFIRMED);
        } else {
            payment.setStatus(PaymentStatus.FAILED);
            order.setPaymentStatus(PaymentStatus.FAILED);
        }

        paymentRepository.save(payment);
        orderRepository.save(order);

        return entityMapper.toPaymentResponse(payment);
    }

    @Override
    @Transactional(readOnly = true)
    public PaymentResponse getByOrderNumber(Long userId, String orderNumber) {
        Payment payment = paymentRepository.findByOrderOrderNumber(orderNumber)
                .orElseThrow(() -> new OrderNotFoundException(
                        "Payment not found for order: " + orderNumber));

        if (!payment.getOrder().getUser().getId().equals(userId)) {
            throw new UnauthorizedAccessException("You are not allowed to view this payment");
        }
        return entityMapper.toPaymentResponse(payment);
    }
}
