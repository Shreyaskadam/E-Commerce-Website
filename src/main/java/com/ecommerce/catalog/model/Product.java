package com.ecommerce.catalog.model;

import com.ecommerce.catalog.records.ProductReview;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Abstract base for all catalog products.
 * Holds shared product state plus:
 * <ul>
 *   <li>static discount rules (f)</li>
 *   <li>final tax rates (f)</li>
 *   <li>static nested utilities CategoryUtils (g)</li>
 * </ul>
 */
public abstract class Product {

  // --- (f) Static discount rules ---
  // Discount percent by category key (for example: ELECTRONICS -> 0.10).
  // Initialized once in the static initializer and then treated as read-only.
  public static final Map<String, BigDecimal> CATEGORY_DISCOUNT_RULES;

  static {
    Map<String, BigDecimal> rules = new LinkedHashMap<>();
    rules.put("ELECTRONICS", new BigDecimal("0.10"));
    rules.put("CLOTHING", new BigDecimal("0.15"));
    rules.put("BOOK", new BigDecimal("0.05"));
    CATEGORY_DISCOUNT_RULES = Collections.unmodifiableMap(rules);
  }

  public static BigDecimal getCategoryDiscountPercent(String categoryKey) {
    return CATEGORY_DISCOUNT_RULES.getOrDefault(
        categoryKey.toUpperCase(),
        BigDecimal.ZERO);
  }

  // --- (f) Final tax rates ---
  // Constant tax rates used by subclasses when calculating their final prices.
  public static final BigDecimal STANDARD_TAX_RATE = new BigDecimal("0.08");
  public static final BigDecimal REDUCED_TAX_RATE = new BigDecimal("0.04");
  public static final BigDecimal LUXURY_TAX_RATE = new BigDecimal("0.12");

  protected final String sku;
  protected final String name;
  protected final BigDecimal basePrice;
  protected final String brand;
  protected final List<ProductReview> reviews;

  /**
   * Protected constructor because {@link Product} is abstract.
   */
  protected Product(String sku, String name, BigDecimal basePrice, String brand) {
    this.sku = Objects.requireNonNull(sku, "sku");
    this.name = Objects.requireNonNull(name, "name");
    this.basePrice = Objects.requireNonNull(basePrice, "basePrice");
    this.brand = Objects.requireNonNull(brand, "brand");
    this.reviews = new ArrayList<>();
  }

  public abstract String getCategoryKey();

  public abstract String getProductTypeDescription();

  public abstract BigDecimal calculateFinalPrice(BigDecimal discountedPrice);

  /**
   * Adds a review to this product.
   */
  public void addReview(ProductReview review) {
    reviews.add(Objects.requireNonNull(review));
  }

  /**
   * Returns an unmodifiable view of reviews to protect internal state.
   */
  public List<ProductReview> getReviews() {
    return Collections.unmodifiableList(reviews);
  }

  /**
   * Calculates the mean rating from all reviews.
   */
  public double getAverageRating() {
    return reviews.stream()
        .mapToInt(ProductReview::rating)
        .average()
        .orElse(0.0);
  }

  protected BigDecimal applyTax(BigDecimal amount, BigDecimal taxRate) {
    // Example: amount=100, rate=0.08 -> tax=8 -> final=108.
    BigDecimal tax = amount.multiply(taxRate);
    return amount.add(tax).setScale(2, RoundingMode.HALF_UP);
  }

  @Override
  public String toString() {
    // ASCII-only separators for consistent console rendering.
    return String.format("[%s] %s - %s ($%s)",
        sku, name, getProductTypeDescription(), basePrice);
  }

  public String getSku() {
    return sku;
  }

  public String getName() {
    return name;
  }

  public BigDecimal getBasePrice() {
    return basePrice;
  }

  public String getBrand() {
    return brand;
  }

  // --- (g) Static nested class ---
  /**
   * Static nested utility class for category/key operations.
   * <p>
   * This exists specifically to demonstrate (g) static nested classes.
   */
  public static class CategoryUtils {

    private CategoryUtils() {
      // Prevent instantiation; this is a static utility holder.
    }

    public static boolean isValidCategory(String categoryKey) {
      // Normalize and check if the key exists in the discount rules map.
      return CATEGORY_DISCOUNT_RULES.containsKey(categoryKey.toUpperCase());
    }

    public static String formatCategoryLabel(String categoryKey) {
      // Convert "ELECTRONICS" -> "Electronics" for nicer printing.
      if (!isValidCategory(categoryKey)) {
        return "Unknown";
      }
      String key = categoryKey.toUpperCase();
      return key.charAt(0) + key.substring(1).toLowerCase();
    }

    public static BigDecimal resolveDiscountFor(Product product) {
      // Lookup discount percent based on the product's category.
      return getCategoryDiscountPercent(product.getCategoryKey());
    }
  }
}
