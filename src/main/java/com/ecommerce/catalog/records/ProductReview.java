package com.ecommerce.catalog.records;

import java.time.LocalDate;

/**
 * Immutable customer review (Java 14+ record).
 */
public record ProductReview(
        /** Name of the reviewer/customer. */
        String reviewerName,
        /** Rating from 1 to 5 (inclusive). */
        int rating,
        /** Optional review comment. */
        String comment,
        /** Date when the review was written. */
        LocalDate reviewDate
) {
    public ProductReview {
        // Validate invariants inside the compact constructor.
        if (rating < 1 || rating > 5) {
            throw new IllegalArgumentException("Rating must be between 1 and 5");
        }
    }
}
