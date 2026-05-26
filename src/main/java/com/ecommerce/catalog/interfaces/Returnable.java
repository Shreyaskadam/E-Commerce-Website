package com.ecommerce.catalog.interfaces;

import java.time.LocalDate;

/**
 * Products eligible for customer returns within a policy window.
 */
public interface Returnable {

    /**
     * @return return window size in days.
     */
    int getReturnWindowDays();

    /**
     * Determines whether a purchase date is eligible for return.
     *
     * @param purchaseDate date the customer bought the product
     * @return true if within the configured return window
     */
    boolean isReturnEligible(LocalDate purchaseDate);

    /**
     * @return human-readable return policy for this product type.
     */
    String getReturnPolicySummary();
}
