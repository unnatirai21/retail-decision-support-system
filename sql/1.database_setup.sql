CREATE DATABASE retail_proj;
USE retail_proj;

CREATE TABLE retail_sales_raw (
    order_id VARCHAR(20),
    customer_id VARCHAR(20),
    product_id VARCHAR(20),
    category VARCHAR(100),
    price DECIMAL(10,2),
    discount DECIMAL(5,2),
    quantity INT,
    payment_method VARCHAR(50),
    order_date DATE,
    delivery_time_days INT,
    region VARCHAR(50),
    returned VARCHAR(10),
    total_amount DECIMAL(10,2),
    shipping_cost DECIMAL(10,2),
    profit_margin DECIMAL(10,2),
    customer_age INT,
    customer_gender VARCHAR(10)
);
select count(*) from retail_sales_raw;
select * from retail_sales_raw limit 10;