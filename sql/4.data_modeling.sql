create table customers as
select distinct customer_id, customer_age, customer_gender 
from rclean;

create table products as
select distinct product_id,category, price, profit_margin 
from rclean;

create table orders as
select order_id,
    customer_id,
    product_id,
    quantity,
    discount,
    payment_method,
    order_date,
    delivery_time_days,
    region,
    returned,
    shipping_cost,
    total_amount from rclean;
    
#create primary,foreign keys
alter table customers
add primary key (customer_id);
alter table products
add primary key (product_id);
alter table orders
add primary key (order_id);

ALTER TABLE orders
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);
SELECT
    order_id,
    COUNT(*) AS cnt
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT
    customer_id,
    COUNT(DISTINCT customer_age) AS age_versions,
    COUNT(DISTINCT customer_gender) AS gender_versions
FROM rclean
GROUP BY customer_id
HAVING age_versions > 1
    OR gender_versions > 1;

SELECT
    product_id,
    COUNT(DISTINCT category) AS category_versions,
    COUNT(DISTINCT price) AS price_versions,
    COUNT(DISTINCT profit_margin) AS margin_versions
FROM rclean
GROUP BY product_id
HAVING category_versions > 1
    OR price_versions > 1
    OR margin_versions > 1;