package com.ecommerce.catalog.model;

import com.ecommerce.catalog.interfaces.Discountable;
import com.ecommerce.catalog.interfaces.Returnable;
import com.ecommerce.catalog.records.ShippingDetails;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;

/**
 * Clothing implements {@link Discountable} and {@link Returnable}.
 * <p>
 * It does not implement {@link Shippable}; instead it provides a helper method
 * for standard apparel shipping.
 */
public class Clothing extends Product implements Discountable, Returnable {

  // Clothing-specific attributes.
  private final String size;
  private final String material;
  private BigDecimal activeDiscountPercent;

  public Clothing(String sku, String name, BigDecimal basePrice, String brand,
      String size, String material) {
    super(sku, name, basePrice, brand);
    this.size = size;
    this.material = material;
    this.activeDiscountPercent = CategoryUtils.resolveDiscountFor(this);
  }

  @Override
  public String getCategoryKey() {
    return "CLOTHING";
  }

  @Override
  public String getProductTypeDescription() {
    // Subclass-specific description (polymorphism demo).
    return String.format("Clothing (size %s, %s)", size, material);
  }

  @Override
  public BigDecimal calculateFinalPrice(BigDecimal discountedPrice) {
    // Clothing uses the standard tax rate.
    return applyTax(discountedPrice, STANDARD_TAX_RATE);
  }

  @Override
  public BigDecimal applyDiscount(BigDecimal discountPercent) {
    // Store discount percent for this instance.
    this.activeDiscountPercent = discountPercent;
    return getDiscountedPrice();
  }

  @Override
  public BigDecimal getDiscountedPrice() {
    // discounted = basePrice * (1 - discountPercent)
    BigDecimal multiplier = BigDecimal.ONE.subtract(activeDiscountPercent);
    return basePrice.multiply(multiplier).setScale(2, RoundingMode.HALF_UP);
  }

  /**
   * Optional helper method for clothing shipping (not part of the Shippable interface).
   */
  public ShippingDetails getStandardApparelShipping() {
    return new ShippingDetails("USPS", new BigDecimal("5.99"), 5, false);
  }

  @Override
  public int getReturnWindowDays() {
    return 45;
  }

  @Override
  public boolean isReturnEligible(LocalDate purchaseDate) {
    // Eligible if purchase date is within the return window from "today".
    return !purchaseDate.isBefore(LocalDate.now().minusDays(getReturnWindowDays()));
  }

  @Override
  public String getReturnPolicySummary() {
    return "Clothing: 45-day return if unworn with tags attached.";
  }

  public String getSize() {
    return size;
  }

  public String getMaterial() {
    return material;
  }
}
