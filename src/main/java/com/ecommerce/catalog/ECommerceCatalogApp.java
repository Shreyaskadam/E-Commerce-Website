package com.ecommerce.catalog;

import com.ecommerce.catalog.interfaces.Discountable;
import com.ecommerce.catalog.interfaces.Returnable;
import com.ecommerce.catalog.interfaces.Shippable;
import com.ecommerce.catalog.model.Book;
import com.ecommerce.catalog.model.Clothing;
import com.ecommerce.catalog.model.Electronics;
import com.ecommerce.catalog.model.Product;
import com.ecommerce.catalog.records.ProductReview;
import com.ecommerce.catalog.records.ShippingDetails;
import com.ecommerce.catalog.service.ProductCatalogService;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Demo application showcasing OOP catalog features (a-h).
 */
public class ECommerceCatalogApp {

  /**
   * Entry point for the console demo.
   * <p>
   * It builds a sample in-memory catalog and then prints results showing:
   * abstract classes/subclasses, interface-based capabilities, records, nested classes,
   * polymorphism/overriding, and lambda-based search/filtering.
   */
  public static void main(String[] args) {
    ProductCatalogService catalog = buildSampleCatalog();

    System.out.println("=== E-Commerce Product Catalog ===\n");
    System.out.println("--- Full catalog ---");
    catalog.printCatalogSummary();

    demonstrateStaticAndNested();
    demonstratePolymorphism(catalog);
    demonstrateRecords(catalog);
    demonstrateInterfaceCapabilities(catalog);
    demonstrateLambdaSearchAndFilter(catalog);
  }

  /**
   * Creates sample products to populate the catalog.
   * <p>
   * In a real system, these would come from a database or external service.
   */
  private static ProductCatalogService buildSampleCatalog() {
    ProductCatalogService catalog = new ProductCatalogService();

    // Electronics: shippable + discountable + returnable.
    Electronics laptop = new Electronics(
        "EL-001", "UltraBook Pro 15", new BigDecimal("1299.99"), "TechCorp",
        24, true);
    laptop.addReview(new ProductReview(
        "Alice", 5, "Fast and lightweight.", LocalDate.of(2025, 3, 10)));

    Clothing jacket = new Clothing(
        "CL-101", "Winter Parka", new BigDecimal("189.99"), "NorthWear",
        "L", "Polyester");
    jacket.addReview(new ProductReview(
        "Bob", 4, "Warm but runs large.", LocalDate.of(2025, 1, 20)));

    // Clothing: discountable + returnable (no Shippable in this demo).
    Book novel = new Book(
        "BK-501", "The Java Journey", new BigDecimal("29.99"), "CodePress",
        "Jane Dev", "978-0134685991", 420);
    novel.addReview(new ProductReview(
        "Carol", 5, "Great for learning OOP.", LocalDate.of(2024, 11, 5)));
    novel.addReview(new ProductReview(
        "Dan", 4, "Solid examples.", LocalDate.of(2025, 2, 1)));

    // Another electronics item without fragility to show different shipping behavior.
    Electronics headphones = new Electronics(
        "EL-002", "NoiseCancel X", new BigDecimal("249.99"), "SoundMax",
        12, false);

    catalog.addProduct(laptop);
    catalog.addProduct(jacket);
    catalog.addProduct(novel);
    catalog.addProduct(headphones);

    return catalog;
  }

  /**
   * Demonstrates static/final rules stored on {@link Product} and the static nested
   * utility class {@link Product.CategoryUtils}.
   */
  private static void demonstrateStaticAndNested() {
    System.out.println("\n--- (f) Static discount rules & final tax rates ---");
    Product.CATEGORY_DISCOUNT_RULES.forEach((cat, pct) ->
        System.out.printf("  %s -> %s%% off%n",
            Product.CategoryUtils.formatCategoryLabel(cat),
            pct.multiply(BigDecimal.valueOf(100))));
    System.out.printf("  Standard tax: %s | Reduced: %s | Luxury: %s%n",
        Product.STANDARD_TAX_RATE,
        Product.REDUCED_TAX_RATE,
        Product.LUXURY_TAX_RATE);

    System.out.println("\n--- (g) Static nested CategoryUtils ---");
    System.out.println("  Valid BOOK? " + Product.CategoryUtils.isValidCategory("BOOK"));
    System.out.println("  Valid TOYS? " + Product.CategoryUtils.isValidCategory("TOYS"));
  }

  /** (d) Polymorphism: Product references, overridden behavior per subtype. */
  private static void demonstratePolymorphism(ProductCatalogService catalog) {
    System.out.println("\n--- (d) Polymorphism & method overriding ---");
    for (Product product : catalog.getAllProducts()) {
      // If the runtime object supports discounts, use the discounted price.
      // Otherwise fall back to the base price.
      BigDecimal discounted = product instanceof Discountable d
          ? d.getDiscountedPrice()
          : product.getBasePrice();
      BigDecimal finalPrice = product.calculateFinalPrice(discounted);
      // calculateFinalPrice() is overridden in each subclass (tax differs by category).
      System.out.printf("  %s -> discounted $%s, final (with tax) $%s%n",
          product.getName(), discounted, finalPrice);
      System.out.printf("    Type: %s%n", product.getProductTypeDescription());
    }
  }

  /**
   * Demonstrates Java records by printing a product's reviews and computing shipping
   * details for shippable products.
   */
  private static void demonstrateRecords(ProductCatalogService catalog) {
    System.out.println("\n--- (e) Records: ProductReview & ShippingDetails ---");
    Product laptop = catalog.filterByCategory("ELECTRONICS").get(0);
    catalog.printReviewsFor(laptop);

    if (laptop instanceof Shippable shippable) {
      ShippingDetails details = shippable.calculateShipping("US");
      System.out.printf("  Shipping: %s via %s, $%s, %d days, tracking=%s%n",
          laptop.getName(),
          details.carrier(),
          details.shippingCost(),
          details.estimatedDays(),
          details.trackingIncluded());
    }
  }

  /** (c) Multiple inheritance via interfaces — each product exposes different capabilities. */
  private static void demonstrateInterfaceCapabilities(ProductCatalogService catalog) {
    System.out.println("\n--- (c) Multiple inheritance via interfaces ---");
    System.out.printf("  Discountable count: %d%n", catalog.getDiscountableProducts().size());
    System.out.printf("  Shippable count: %d%n", catalog.getShippableProducts().size());
    System.out.printf("  Returnable count: %d%n", catalog.getReturnableProducts().size());

    catalog.getReturnableProducts().forEach(r ->
        System.out.println("  Return policy: " + r.getReturnPolicySummary()));
  }

  /** (h) Lambda expressions for search and filter. */
  private static void demonstrateLambdaSearchAndFilter(ProductCatalogService catalog) {
    System.out.println("\n--- (h) Lambda search & filter ---");

    List<Product> proMatches = catalog.searchByName("pro");
    System.out.println("  Search 'pro': " + namesOf(proMatches));

    List<Product> books = catalog.filterByCategory("BOOK");
    System.out.println("  Category BOOK: " + namesOf(books));

    List<Product> affordable = catalog.filterByMaxPrice(new BigDecimal("300.00"));
    System.out.println("  Price <= $300: " + namesOf(affordable));

    List<Product> highlyRated = catalog.filterByMinAverageRating(4.5);
    System.out.println("  Avg rating >= 4.5: " + namesOf(highlyRated));

    List<Product> complex = catalog.findProductsMatching(
        p -> p.getBasePrice().compareTo(new BigDecimal("50")) > 0,
        p -> p.getCategoryKey().equals("ELECTRONICS"));
    System.out.println("  Electronics over $50: " + namesOf(complex));

    List<Product> byPrice = catalog.sortByPriceAscending();
    System.out.println("  Sorted by price: " + namesOf(byPrice));
  }

  private static String namesOf(List<Product> products) {
    return products.stream()
        .map(Product::getName)
        .reduce((a, b) -> a + ", " + b)
        .orElse("(none)");
  }
}
