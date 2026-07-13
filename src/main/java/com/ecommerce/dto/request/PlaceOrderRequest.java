package com.ecommerce.dto.request;

import com.ecommerce.enums.PaymentMethod;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PlaceOrderRequest {

    @NotNull(message = "Payment method is required for order placement")
    private PaymentMethod paymentMethod;
}
