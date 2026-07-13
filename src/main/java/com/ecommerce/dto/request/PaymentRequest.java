package com.ecommerce.dto.request;

import com.ecommerce.enums.PaymentMethod;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PaymentRequest {

    @NotBlank(message = "Order number is required")
    private String orderNumber;

    @NotNull(message = "Payment method is required")
    private PaymentMethod paymentMethod;

    /** When true, simulation records SUCCESS; when false, FAILED. Defaults to success. */
    private Boolean simulateSuccess = true;
}
