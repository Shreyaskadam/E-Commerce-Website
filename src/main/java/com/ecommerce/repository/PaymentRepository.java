package com.ecommerce.repository;

import com.ecommerce.entity.Payment;
import com.ecommerce.enums.PaymentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.Optional;

public interface PaymentRepository extends JpaRepository<Payment, Long> {

    @Query("""
            SELECT p FROM Payment p
            JOIN FETCH p.order o
            JOIN FETCH o.user
            WHERE o.orderNumber = :orderNumber
            """)
    Optional<Payment> findByOrderOrderNumber(@Param("orderNumber") String orderNumber);

    boolean existsByOrderIdAndStatus(Long orderId, PaymentStatus status);

    @Query("""
            SELECT COALESCE(SUM(p.amount), 0)
            FROM Payment p
            WHERE p.status = com.ecommerce.enums.PaymentStatus.SUCCESS
            """)
    BigDecimal sumSuccessfulPaymentAmount();

    long countByStatus(PaymentStatus status);
}
