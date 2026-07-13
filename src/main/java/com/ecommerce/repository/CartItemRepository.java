package com.ecommerce.repository;

import com.ecommerce.entity.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    @Query("""
            SELECT ci FROM CartItem ci
            JOIN FETCH ci.product
            JOIN FETCH ci.cart c
            WHERE ci.id = :id AND c.user.id = :userId
            """)
    Optional<CartItem> findByIdAndCartUserId(@Param("id") Long id, @Param("userId") Long userId);
}
