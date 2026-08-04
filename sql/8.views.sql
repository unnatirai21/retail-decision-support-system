-- description: core business views for executive reporting, dashboards, and crm.
-- objective: encapsulate repetitive business logic into reusable database objects.

use retail_proj;

-- view 1: customer summary
-- primary users: crm & growth marketing teams
drop view if exists customer_summary;

create view customer_summary as
select
    c.customer_id as customer_id, c.customer_age as age,
    c.customer_gender as gender,
    count(o.order_id) as total_orders,
    round(sum(o.total_amount), 2) as total_spending,
    round(avg(o.total_amount), 2) as avg_order_value
from customers c
join orders o on
c.customer_id=o.customer_id
group by c.customer_id, c.customer_age,c.customer_gender;

-- view 2: product performance
-- primary users: product managers & catalog teams
drop view if exists product_performance;

create view product_performance as
select
    p.product_id as product_id,
    p.category as category,
    sum(o.quantity) as units_sold,
    round(sum(o.total_amount), 2) as revenue,
    round(avg(p.profit_margin), 2) as avg_profit_margin
from products p join orders o
on p.product_id=o.product_id
group by p.product_id, p.category;

-- view 3: monthly sales
-- primary users: finance & executive leadership
drop view if exists monthly_sales;

create view monthly_sales as
select
    date_format(order_date, '%Y-%m') as month,
    count(order_id) as orders,
    round(sum(total_amount), 2) as revenue,
    round(avg(total_amount), 2) as avg_order_value
from rclean
group by month;

-- view 4: regional performance
-- primary users: operations, logistics & regional managers
drop view if exists region_performance;

create view region_performance as
select
    region,
    round(sum(total_amount), 2) as revenue,
    round(avg(delivery_time_days), 2) as avg_delivery_time,
    round(avg(returned = 'Yes') * 100, 2) as return_rate
from rclean
group by region;

-- view 5: category performance
-- primary users: merchandising & inventory planning teams
drop view if exists category_performance;

create view category_performance as
select
    category,
    sum(quantity) as units_sold,
    round(sum(total_amount), 2) as revenue,
    round(avg(discount) * 100, 2) as avg_discount,
    round(avg(profit_margin), 2) as avg_profit_margin
from rclean
group by category;

-- view 6: high-value customers
-- primary users: vip loyalty & retention teams
drop view if exists high_value_customers;

create view high_value_customers as
select *
from customer_summary
where total_spending >= 5000;

-- view 7: return analysis
-- primary users: quality assurance, operations & vendor management
drop view if exists return_analysis;

create view return_analysis as
select
    product_id,
    count(*) as total_orders,
    sum(returned = 'Yes') as returned_orders,
    round(avg(returned = 'Yes') * 100, 2) as return_rate
from rclean 
group by product_id;

-- test queries:
show full tables where table_type = 'VIEW';
select * from customer_summary order by total_spending desc limit 20;
select * from product_performance order by revenue desc limit 20;
select * from monthly_sales order by month;
select * from region_performance order by revenue desc;
select * from high_value_customers order by total_spending desc;
select * from category_performance order by revenue desc;
select * from return_analysis having total_orders >= 5 order by return_rate desc;
