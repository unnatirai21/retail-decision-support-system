select count(*) as total_rows from retail_sales_raw;

#duplicate orders:none
select order_id, count(*) as duplicate_orders from retail_sales_raw group by order_id having count(*)>1;

#missing values
select
sum(order_id is null) as orderid_null,
sum(customer_id is null) as customer_null,
sum(product_id is null) as prod_null,
sum(category is null) as cat_null,
sum(price is null) as price_null,
SUM(discount is null) discount,
SUM(quantity is null) quantity,
SUM(payment_method is null) payment_method,
SUM(order_date is null) order_date,
SUM(delivery_time_days is null) delivery_time_days,
SUM(region is null) region,
SUM(returned is null) returned,
SUM(total_amount is null) total_amount,
SUM(shipping_cost is null) shipping_cost,
SUM(profit_margin is null) profit_margin,
SUM(customer_age is null) customer_age,
SUM(customer_gender is null) customer_gender
FROM retail_sales_raw;

#range
SELECT
MIN(price),
MAX(price),
MIN(discount),
MAX(discount),
MIN(quantity),
MAX(quantity),
MIN(customer_age),
MAX(customer_age),
MIN(delivery_time_days),
MAX(delivery_time_days)
FROM retail_sales_raw;

#category distribution
select category, count(*) as orders from retail_sales_raw
group by category order by orders desc;

#payment method distribution
select payment_method, count(*) as orders from retail_sales_raw
group by payment_method order by orders desc;

#region distribution
select region, count(*) as orders from retail_sales_raw
group by region order by orders desc;