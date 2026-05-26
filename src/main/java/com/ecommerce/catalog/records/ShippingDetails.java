package com.ecommerce.catalog.records;

import java.math.BigDecimal;

/**
 * Immutable shipping quote (Java 14+ record).
 */
public record ShippingDetails(
        /** Shipping carrier/service name (e.g., FedEx, USPS, Media Mail). */
        String carrier,
        /** Monetary shipping cost for the selected shipping method. */
        BigDecimal shippingCost,
        /** Delivery time estimate in days. */
        int estimatedDays,
        /** Whether a tracking number is included. */
        boolean trackingIncluded
) {
}
