package com.ecommerce.catalog.interfaces;

import java.math.BigDecimal;

/**
 * Products that support percentage-based discounts.
 */
public interface Discountable {

    /**
     * @return the original (non-discounted) base price.
     */
    BigDecimal getBasePrice();

    /**
     * Applies a discount percent and updates the internal discounted-price state
     * for the implementing product.
     *
     * @param discountPercent percentage discount as a decimal (e.g. 0.10 for 10%)
     * @return discounted price
     */
    BigDecimal applyDiscount(BigDecimal discountPercent);

    /**
     * @return the discounted price computed using the product's current discount percent.
     */
    BigDecimal getDiscountedPrice();
}
