#CUSTOMER LIFETIME VALUE (CLV)
use retail_proj;
delimiter $$
drop procedure if exists CLV $$
create procedure CLV()
begin
select c.customer_id as customer_id,
min(o.order_date) as first_purchase,
max(o.order_date) as last_purchase,
count(o.order_id) as total_orders,
round(sum(o.total_amount),2) as lifetime_val,
round(avg(o.total_amount),2) as avg_order_val
from customers c
join orders o 
on c.customer_id=o.customer_id
group by c.customer_id
order by lifetime_val desc;
end$$
delimiter ;
call CLV();

#REGION PERFORMANCE SCORE: (RPS)
use retail_proj;
delimiter $$
DROP PROCEDURE IF EXISTS RPS $$
create procedure RPS()
begin
select region, 
round(sum(total_amount),2) revenue,
round(avg(returned='Yes')*100,2) return_rate,
round(avg(delivery_time_days),2) avg_delivery
from rclean
group by region
order by revenue desc;
end$$
delimiter ;
call RPS();

#ABC INVENTORY CLASSIFICATION (PARETO BASED)
use retail_proj;
delimiter $$
drop procedure if exists ABC1 $$
create procedure ABC1()
begin
with product_sale as(
select product_id,
round(sum(total_amount),2) revenue
from rclean group by product_id),
pareto as(
select product_id, revenue,
sum(revenue) over(order by revenue desc) as cumulative_rev,
sum(revenue) over() as total_revenue
from product_sale)
select
product_id, revenue, 
round(cumulative_rev/total_revenue*100,2) as cum_percentage,
case 
when cumulative_rev/total_revenue<=0.70 then 'A'
when cumulative_rev/total_revenue<=0.90 then 'B'
else 'C'
end as inventory_class
from pareto order by revenue desc;
end $$
delimiter ;
call ABC1();

#RISK FLAGGING: RF()
use retail_proj;
delimiter $$
drop procedure if exists RF $$
create procedure RF()
begin
select customer_id, 
order_date,
count(order_id) as total_orders,
round(sum(total_amount),2) as spending,
sum(returned='Yes') as returned_orders,
CASE
when count(order_id)>=5 then 'Velocity Anomaly — Review for Bot/Bulk Activity'
when sum(returned = 'Yes') >= 3 then 'Return Pattern Anomaly — Review for Refund Abuse'
 when sum(total_amount)>=10000 and count(order_id)<=2 then 'High Value Order- Watchlist'
        end risk_flag
from rclean
group by customer_id, order_date
having count(order_id)>=5 or
(sum(total_amount)>10000 and count(order_id)<=2) or
sum(returned='Yes')>=3
order by spending desc;
end $$
delimiter ;
call RF();

#EXECUTIVE DASHBOARD: ED()
use retail_proj;
delimiter $$
drop procedure if exists ED $$
create procedure ED()

begin
with
-- overall business metrics
overall_metrics as (
select
round(sum(total_amount),2) as total_revenue,
count(order_id) as total_orders,
count(distinct customer_id) as total_customers,
round(avg(total_amount),2) as average_order_value,
round(avg(returned='Yes')*100,2) as return_rate,
round(avg(delivery_time_days),2) as average_delivery_days
from rclean
),

-- top category
top_category as (
select
category,
sum(total_amount) revenue,
row_number()
over(order by sum(total_amount) desc) as rn
from rclean group by category
),

-- top region
top_region as (
select
region,
sum(total_amount) revenue,
row_number()
over(order by sum(total_amount) desc) as rn
from rclean group by region
),

-- best customer
best_customer as (
select
customer_id,
sum(total_amount) spending,
row_number() over(order by sum(total_amount) desc) as rn
from rclean group by customer_id
),

-- best payment method
best_payment as (
select
payment_method,
avg(profit_margin) avg_margin,
row_number()
over(order by avg(profit_margin) desc) as rn
from rclean group by payment_method
)

-- final dashboard
select
o.total_revenue,
o.total_orders,
o.total_customers,
o.average_order_value,
o.return_rate,
o.average_delivery_days,
tc.category as top_category,
tr.region as top_region,
bc.customer_id as best_customer,
bp.payment_method as best_payment_method
from overall_metrics o
cross join top_category tc
cross join top_region tr
cross join best_customer bc
cross join best_payment bp
where
tc.rn = 1
and tr.rn = 1
and bc.rn = 1
and bp.rn = 1;
end $$
delimiter ;
call ED();