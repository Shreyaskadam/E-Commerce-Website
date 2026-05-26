package com.ecommerce.catalog.model;

import com.ecommerce.catalog.interfaces.Discountable;
import com.ecommerce.catalog.interfaces.Returnable;
import com.ecommerce.catalog.interfaces.Shippable;
import com.ecommerce.catalog.records.ShippingDetails;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.Objects;

/**
 * Electronics implements all three interfaces:
 * {@link Discountable}, {@link Shippable}, and {@link Returnable}.
 * <p>
 * This demonstrates multiple inheritance via interfaces (c).
 */
public class Electronics extends Product
    implements Discountable, Shippable, Returnable {

  // Electronics-specific attributes.
  private final int warrantyMonths;
  private final boolean fragile;

  /**
   * Current discount percent for this specific product instance.
   * Initialized from static category rules in the constructor.
   */
  private BigDecimal activeDiscountPercent;

  public Electronics(String sku, String name, BigDecimal basePrice, String brand,
      int warrantyMonths, boolean fragile) {
    super(sku, name, basePrice, brand);
    this.warrantyMonths = warrantyMonths;
    this.fragile = fragile;
    this.activeDiscountPercent = CategoryUtils.resolveDiscountFor(this);
  }

  @Override
  public String getCategoryKey() {
    return "ELECTRONICS";
  }

  @Override
  public String getProductTypeDescription() {
    // Subclass-specific description (polymorphism demo).
    return String.format("Electronics (%d-mo warranty%s)",
        warrantyMonths, fragile ? ", fragile" : "");
  }

  @Override
  public BigDecimal calculateFinalPrice(BigDecimal discountedPrice) {
    // Luxury tax rate for electronics.
    return applyTax(discountedPrice, LUXURY_TAX_RATE);
  }

  // --- Discountable ---
  @Override
  public BigDecimal applyDiscount(BigDecimal discountPercent) {
    // Store the new discount percent and compute discounted price.
    this.activeDiscountPercent = discountPercent;
    return getDiscountedPrice();
  }

  @Override
  public BigDecimal getDiscountedPrice() {
    // discounted = basePrice * (1 - discountPercent)
    BigDecimal multiplier = BigDecimal.ONE.subtract(activeDiscountPercent);
    return basePrice.multiply(multiplier).setScale(2, RoundingMode.HALF_UP);
  }

  // --- Shippable ---
  @Override
  public ShippingDetails calculateShipping(String destinationCountry) {
    // Shipping cost depends on fragility and destination.
    Objects.requireNonNull(destinationCountry);
    BigDecimal cost = fragile
        ? new BigDecimal("24.99")
        : new BigDecimal("12.99");
    if (!"US".equalsIgnoreCase(destinationCountry)) {
      cost = cost.add(new BigDecimal("18.00"));
    }
    return new ShippingDetails("FedEx", cost, getEstimatedDeliveryDays(), true);
  }

  @Override
  public int getEstimatedDeliveryDays() {
    return fragile ? 7 : 4;
  }

  @Override
  public boolean requiresSpecialHandling() {
    return fragile;
  }

  // --- Returnable ---
  @Override
  public int getReturnWindowDays() {
    return 30;
  }

  @Override
  public boolean isReturnEligible(LocalDate purchaseDate) {
    // Eligible if purchase date is within the return window from "today".
    return !purchaseDate.isBefore(LocalDate.now().minusDays(getReturnWindowDays()));
  }

  @Override
  public String getReturnPolicySummary() {
    return "Electronics: 30-day return with original packaging and receipt.";
  }

  public int getWarrantyMonths() {
    return warrantyMonths;
  }

  public boolean isFragile() {
    return fragile;
  }
}
