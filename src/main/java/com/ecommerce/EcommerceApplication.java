package com.ecommerce;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class EcommerceApplication {

    public static void main(String[] args) {
        SpringApplication.run(EcommerceApplication.class, args);
    }
}

/*
http://localhost:8080/api/auth/register
http://localhost:8080/api/auth/login
http://localhost:8080/api/products
http://localhost:8080/api/cart/items
http://localhost:8080/api/orders
http://localhost:8080/api/payments

http://localhost:8080/api/products
http://localhost:8080/api/products/1
http://localhost:8080/api/cart
http://localhost:8080/api/payments/order/ORD-A1B2C3D4
http://localhost:8080/api/reports/top-selling-products?limit=10
*/