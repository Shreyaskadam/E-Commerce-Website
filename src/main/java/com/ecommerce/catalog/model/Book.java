package com.ecommerce.catalog.model;

import com.ecommerce.catalog.interfaces.Discountable;
import com.ecommerce.catalog.interfaces.Shippable;
import com.ecommerce.catalog.records.ShippingDetails;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Book implements {@link Discountable} and {@link Shippable}.
 * <p>
 * It demonstrates category-specific tax and a custom shipping method (Media Mail).
 */
public class Book extends Product implements Discountable, Shippable {

  // Book-specific attributes.
  private final String author;
  private final String isbn;
  private final int pageCount;
  private BigDecimal activeDiscountPercent;

  public Book(String sku, String name, BigDecimal basePrice, String brand,
      String author, String isbn, int pageCount) {
    super(sku, name, basePrice, brand);
    this.author = author;
    this.isbn = isbn;
    this.pageCount = pageCount;
    this.activeDiscountPercent = CategoryUtils.resolveDiscountFor(this);
  }

  @Override
  public String getCategoryKey() {
    return "BOOK";
  }

  @Override
  public String getProductTypeDescription() {
    // Subclass-specific description (polymorphism demo).
    return String.format("Book by %s (%d pages, ISBN %s)", author, pageCount, isbn);
  }

  @Override
  public BigDecimal calculateFinalPrice(BigDecimal discountedPrice) {
    // Books use the reduced tax rate.
    return applyTax(discountedPrice, REDUCED_TAX_RATE);
  }

  @Override
  public BigDecimal applyDiscount(BigDecimal discountPercent) {
    // Store discount percent and compute discounted price.
    this.activeDiscountPercent = discountPercent;
    return getDiscountedPrice();
  }

  @Override
  public BigDecimal getDiscountedPrice() {
    // discounted = basePrice * (1 - discountPercent)
    BigDecimal multiplier = BigDecimal.ONE.subtract(activeDiscountPercent);
    return basePrice.multiply(multiplier).setScale(2, RoundingMode.HALF_UP);
  }

  @Override
  public ShippingDetails calculateShipping(String destinationCountry) {
    // destinationCountry is not used in this demo; shipping depends on page count.
    BigDecimal cost = pageCount > 500
        ? new BigDecimal("4.99")
        : new BigDecimal("3.49");
    return new ShippingDetails("Media Mail", cost, getEstimatedDeliveryDays(), false);
  }

  @Override
  public int getEstimatedDeliveryDays() {
    return 6;
  }

  @Override
  public boolean requiresSpecialHandling() {
    return false;
  }

  public String getAuthor() {
    return author;
  }

  public String getIsbn() {
    return isbn;
  }

  public int getPageCount() {
    return pageCount;
  }
}
