package com.ecommerce.repository;

import com.ecommerce.entity.OrderItem;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {

    @Query("""
            SELECT oi.productId, oi.productName, SUM(oi.quantity)
            FROM OrderItem oi
            JOIN oi.order o
            WHERE o.paymentStatus = com.ecommerce.enums.PaymentStatus.SUCCESS
               OR o.status = com.ecommerce.enums.OrderStatus.CONFIRMED
            GROUP BY oi.productId, oi.productName
            ORDER BY SUM(oi.quantity) DESC
            """)
    List<Object[]> findTopSellingProducts(Pageable pageable);
}
