package com.ecommerce.service.impl;

import com.ecommerce.dto.request.PlaceOrderRequest;
import com.ecommerce.dto.response.OrderResponse;
import com.ecommerce.entity.*;
import com.ecommerce.enums.OrderStatus;
import com.ecommerce.enums.PaymentStatus;
import com.ecommerce.exception.*;
import com.ecommerce.mapper.EntityMapper;
import com.ecommerce.repository.CartRepository;
import com.ecommerce.repository.OrderRepository;
import com.ecommerce.repository.ProductRepository;
import com.ecommerce.service.OrderService;
import com.ecommerce.util.PricingRules;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrderServiceImpl implements OrderService {

    private final CartRepository cartRepository;
    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final EntityMapper entityMapper;

    @Override
    @Transactional
    public OrderResponse placeOrder(Long userId, PlaceOrderRequest request) {
        Cart cart = cartRepository.findByUserIdWithItems(userId)
                .orElseThrow(() -> new CartNotFoundException("Cart not found for user"));

        if (cart.getItems() == null || cart.getItems().isEmpty()) {
            throw new CartEmptyException("Cannot place order with an empty cart");
        }

        BigDecimal totalDiscount = BigDecimal.ZERO;
        BigDecimal totalTax = BigDecimal.ZERO;
        BigDecimal totalAmount = BigDecimal.ZERO;
        List<OrderItem> orderItems = new ArrayList<>();

        Order order = Order.builder()
                .orderNumber(generateOrderNumber())
                .user(cart.getUser())
                .status(OrderStatus.CREATED)
                .paymentStatus(PaymentStatus.PENDING)
                .discountAmount(BigDecimal.ZERO)
                .taxAmount(BigDecimal.ZERO)
                .totalAmount(BigDecimal.ZERO)
                .items(new ArrayList<>())
                .build();

        for (CartItem cartItem : cart.getItems()) {
            Product product = productRepository.findById(cartItem.getProduct().getId())
                    .orElseThrow(() -> new ProductNotFoundException(
                            "Product not found: " + cartItem.getProduct().getId()));

            if (!product.isActive()) {
                throw new InvalidRequestException("Product is inactive: " + product.getName());
            }
            if (cartItem.getQuantity() > product.getStockQuantity()) {
                throw new InsufficientStockException(
                        "Insufficient stock for product: " + product.getName()
                                + " (available: " + product.getStockQuantity() + ")");
            }

            BigDecimal listPrice = product.getPrice();
            BigDecimal discountedUnit = PricingRules.applyDiscount(listPrice, product.getCategory());
            BigDecimal lineDiscount = listPrice.subtract(discountedUnit)
                    .multiply(BigDecimal.valueOf(cartItem.getQuantity()))
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal lineSubtotalBeforeTax = discountedUnit
                    .multiply(BigDecimal.valueOf(cartItem.getQuantity()))
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal lineTax = PricingRules.calculateTax(lineSubtotalBeforeTax, product.getCategory());
            BigDecimal lineTotal = lineSubtotalBeforeTax.add(lineTax).setScale(2, RoundingMode.HALF_UP);

            OrderItem orderItem = OrderItem.builder()
                    .order(order)
                    .productId(product.getId())
                    .productName(product.getName())
                    .quantity(cartItem.getQuantity())
                    .unitPrice(discountedUnit)
                    .subtotal(lineTotal)
                    .build();
            orderItems.add(orderItem);

            totalDiscount = totalDiscount.add(lineDiscount);
            totalTax = totalTax.add(lineTax);
            totalAmount = totalAmount.add(lineTotal);

            product.setStockQuantity(product.getStockQuantity() - cartItem.getQuantity());
            productRepository.save(product);
        }

        order.setItems(orderItems);
        order.setDiscountAmount(totalDiscount);
        order.setTaxAmount(totalTax);
        order.setTotalAmount(totalAmount);

        // Simulated pending payment record created with the order; finalize via /api/payments
        Payment payment = Payment.builder()
                .paymentReference("PAY-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .order(order)
                .amount(totalAmount)
                .paymentMethod(request.getPaymentMethod())
                .status(PaymentStatus.PENDING)
                .build();
        order.setPayment(payment);

        Order saved = orderRepository.save(order);

        cart.clearItems();
        cartRepository.save(cart);

        return entityMapper.toOrderResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public List<OrderResponse> getMyOrders(Long userId) {
        return orderRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(entityMapper::toOrderResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public OrderResponse getByOrderNumber(Long userId, String orderNumber) {
        Order order = orderRepository.findByOrderNumberWithItems(orderNumber)
                .orElseThrow(() -> new OrderNotFoundException("Order not found: " + orderNumber));

        if (!order.getUser().getId().equals(userId)) {
            throw new UnauthorizedAccessException("You are not allowed to view this order");
        }
        return entityMapper.toOrderResponse(order);
    }

    private String generateOrderNumber() {
        return "ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }
}
