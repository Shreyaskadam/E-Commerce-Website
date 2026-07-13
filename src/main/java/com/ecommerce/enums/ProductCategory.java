package com.ecommerce.enums;

/**
 * Replaces the old Electronics / Clothing / Book subclasses.
 * A single Product entity with this enum is cleaner for JPA than inheritance hierarchies.
 */
public enum ProductCategory {
    ELECTRONICS,
    CLOTHING,
    BOOK
}
