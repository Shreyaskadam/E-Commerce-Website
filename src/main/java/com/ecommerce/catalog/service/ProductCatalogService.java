package com.ecommerce.catalog.service;

import com.ecommerce.catalog.interfaces.Discountable;
import com.ecommerce.catalog.interfaces.Returnable;
import com.ecommerce.catalog.interfaces.Shippable;
import com.ecommerce.catalog.model.Product;
import com.ecommerce.catalog.records.ProductReview;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.function.Predicate;
import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * Catalog operations with lambda-based search and filter (h).
 */
public class ProductCatalogService {

  // In-memory catalog store for demo purposes.
  private final List<Product> catalog = new ArrayList<>();

  /**
   * Adds a product to the catalog.
   * <p>
   * In a real application this would likely persist to a DB.
   */
  public void addProduct(Product product) {
    catalog.add(Objects.requireNonNull(product));
  }

  /**
   * Returns a defensive copy so callers cannot mutate our internal list.
   */
  public List<Product> getAllProducts() {
    return List.copyOf(catalog);
  }

  // --- Lambda search & filter ---

  /**
   * Searches by product name using a case-insensitive "contains" check.
   * Demonstrates streams + lambdas.
   */
  public List<Product> searchByName(String keyword) {
    String lower = keyword.toLowerCase();
    return catalog.stream()
        .filter(p -> p.getName().toLowerCase().contains(lower))
        .collect(Collectors.toList());
  }

  /**
   * Filters by the product category key (e.g. ELECTRONICS, CLOTHING, BOOK).
   */
  public List<Product> filterByCategory(String categoryKey) {
    String key = categoryKey.toUpperCase();
    return catalog.stream()
        .filter(p -> p.getCategoryKey().equals(key))
        .collect(Collectors.toList());
  }

  /**
   * Filters products whose base price is less than or equal to {@code maxPrice}.
   */
  public List<Product> filterByMaxPrice(BigDecimal maxPrice) {
    return catalog.stream()
        .filter(p -> p.getBasePrice().compareTo(maxPrice) <= 0)
        .collect(Collectors.toList());
  }

  /**
   * Filters products whose average rating (from {@link com.ecommerce.catalog.records.ProductReview})
   * is greater than or equal to the provided threshold.
   */
  public List<Product> filterByMinAverageRating(double minRating) {
    return catalog.stream()
        .filter(p -> p.getAverageRating() >= minRating)
        .collect(Collectors.toList());
  }

  /**
   * Generic filter method that accepts any lambda predicate.
   * This is the most flexible part of the demo.
   */
  public List<Product> filter(Predicate<Product> criteria) {
    return catalog.stream()
        .filter(criteria)
        .collect(Collectors.toList());
  }

  /**
   * Returns all products that implement {@link Discountable}.
   * <p>
   * Demonstrates "multiple inheritance" via interfaces using runtime checks.
   */
  public List<Discountable> getDiscountableProducts() {
    return catalog.stream()
        .filter(Discountable.class::isInstance)
        .map(Discountable.class::cast)
        .collect(Collectors.toList());
  }

  /**
   * Returns all products that implement {@link Shippable}.
   */
  public List<Shippable> getShippableProducts() {
    return catalog.stream()
        .filter(Shippable.class::isInstance)
        .map(Shippable.class::cast)
        .collect(Collectors.toList());
  }

  /**
   * Returns all products that implement {@link Returnable}.
   */
  public List<Returnable> getReturnableProducts() {
    return catalog.stream()
        .filter(Returnable.class::isInstance)
        .map(Returnable.class::cast)
        .collect(Collectors.toList());
  }

  /**
   * Sorts by the base price ascending.
   */
  public List<Product> sortByPriceAscending() {
    return catalog.stream()
        .sorted(Comparator.comparing(Product::getBasePrice))
        .collect(Collectors.toList());
  }

  /**
   * Combines multiple predicate lambdas into a single AND filter.
   */
  @SafeVarargs
  public final List<Product> findProductsMatching(Predicate<Product>... predicates) {
    Predicate<Product> combined = Arrays.stream(predicates)
        .reduce(Predicate::and)
        .orElse(p -> true);
    return filter(combined);
  }

  /**
   * Prints the catalog summary to the console.
   */
  public void printCatalogSummary() {
    catalog.forEach(p -> System.out.println("  - " + p));
  }

  /**
   * Prints all reviews attached to a given product.
   */
  public void printReviewsFor(Product product) {
    System.out.println("Reviews for " + product.getName() + ":");
    product.getReviews().forEach(r ->
        // Use ASCII characters for cleaner console output on any platform/codepage.
        System.out.printf("  * %d - %s (%s): %s%n",
            r.rating(), r.reviewerName(), r.reviewDate(), r.comment()));
  }
}
