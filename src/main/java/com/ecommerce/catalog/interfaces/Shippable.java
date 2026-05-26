package com.ecommerce.catalog.interfaces;

import com.ecommerce.catalog.records.ShippingDetails;

/**
 * Products that can be shipped to customers.
 */
public interface Shippable {

    /**
     * Calculates a shipping quote for a destination country.
     */
    ShippingDetails calculateShipping(String destinationCountry);

    /**
     * @return an estimated delivery time in days.
     */
    int getEstimatedDeliveryDays();

    /**
     * @return true if the product should be handled specially (e.g., fragile items).
     */
    boolean requiresSpecialHandling();
}
