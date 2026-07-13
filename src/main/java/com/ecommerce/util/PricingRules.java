package com.ecommerce.util;

import com.ecommerce.enums.ProductCategory;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collections;
import java.util.EnumMap;
import java.util.Map;

/**
 * Preserves category discount and tax rules from the original Core Java Product class.
 * Electronics: 10% discount, 12% luxury tax
 * Clothing: 15% discount, 8% standard tax
 * Book: 5% discount, 4% reduced tax
 */
public final class PricingRules {

    public static final BigDecimal STANDARD_TAX_RATE = new BigDecimal("0.08");
    public static final BigDecimal REDUCED_TAX_RATE = new BigDecimal("0.04");
    public static final BigDecimal LUXURY_TAX_RATE = new BigDecimal("0.12");

    private static final Map<ProductCategory, BigDecimal> CATEGORY_DISCOUNT_RULES;
    private static final Map<ProductCategory, BigDecimal> CATEGORY_TAX_RATES;

    static {
        Map<ProductCategory, BigDecimal> discounts = new EnumMap<>(ProductCategory.class);
        discounts.put(ProductCategory.ELECTRONICS, new BigDecimal("0.10"));
        discounts.put(ProductCategory.CLOTHING, new BigDecimal("0.15"));
        discounts.put(ProductCategory.BOOK, new BigDecimal("0.05"));
        CATEGORY_DISCOUNT_RULES = Collections.unmodifiableMap(discounts);

        Map<ProductCategory, BigDecimal> taxes = new EnumMap<>(ProductCategory.class);
        taxes.put(ProductCategory.ELECTRONICS, LUXURY_TAX_RATE);
        taxes.put(ProductCategory.CLOTHING, STANDARD_TAX_RATE);
        taxes.put(ProductCategory.BOOK, REDUCED_TAX_RATE);
        CATEGORY_TAX_RATES = Collections.unmodifiableMap(taxes);
    }

    private PricingRules() {
    }

    public static BigDecimal getDiscountPercent(ProductCategory category) {
        return CATEGORY_DISCOUNT_RULES.getOrDefault(category, BigDecimal.ZERO);
    }

    public static BigDecimal getTaxRate(ProductCategory category) {
        return CATEGORY_TAX_RATES.getOrDefault(category, STANDARD_TAX_RATE);
    }

    public static BigDecimal applyDiscount(BigDecimal unitPrice, ProductCategory category) {
        BigDecimal discountPercent = getDiscountPercent(category);
        BigDecimal multiplier = BigDecimal.ONE.subtract(discountPercent);
        return unitPrice.multiply(multiplier).setScale(2, RoundingMode.HALF_UP);
    }

    public static BigDecimal calculateTax(BigDecimal amount, ProductCategory category) {
        return amount.multiply(getTaxRate(category)).setScale(2, RoundingMode.HALF_UP);
    }

    public static BigDecimal applyTax(BigDecimal amount, ProductCategory category) {
        return amount.add(calculateTax(amount, category)).setScale(2, RoundingMode.HALF_UP);
    }
}
