#WINDOW FUNCTIONS AND RANKS

#Within each category, which products generate the highest revenue?
select product_id, category, sum(total_amount) as revenue,
rank() over( partition by category order by sum(total_amount) desc) as revenue_rank
from rclean group by product_id, category;

select product_id, category, sum(total_amount) as revenue,
dense_rank() over( partition by category order by sum(total_amount) desc) as revenue_rank
from rclean group by product_id, category;

#Top 5 products in each category
with ranked as(
select p.product_id as product_id, 
p.category as category, 
sum(o.total_amount) as revenue,
row_number() over(
partition by p.category 
order by sum(o.total_amount) desc) rn
from products p join orders o
on p.product_id=o.product_id
group by product_id, category)
select * from ranked where rn<=5;

#RUNNING TOTALS: MONTHLY CUMULATVE REVENUE
with month_sales as(
select date_format(order_date, '%Y-%m') as month,
sum(total_amount) as revenue from rclean group by month)
select month, revenue, sum(revenue) over (order by month) as
cumulative_revenue from month_sales;

#LAG: MONTH OVER MONTH GROWTH
with month_sales as(
select date_format(order_date, '%Y-%m') as month,
sum(total_amount) as revenue from rclean group by month)
select month, revenue, lag(revenue) over(order by month) as previous_month,
round(
(revenue-lag(revenue) over(order by month))/
lag(revenue) over(order by month)*100,2)
as growth_percent from month_sales;

#or
with monthly_sales as(
select date_format(order_date,'%Y-%m') as month,
sum(total_amount) as revenue from rclean group by month),

monthly_growth as(
select month, revenue, lag(revenue) over(order by month) as prev_month
from monthly_sales)
select month, revenue, prev_month,
round(((revenue-prev_month)/prev_month)*100,2) as growth_percent
from monthly_growth;

#LEAD (FORECASTING): COMPARE MONTH'S REVENUE W FOLLOWING MONTH'S REVENUE
with monthly_sales as(
select date_format(order_date, '%Y-%m') as month,
sum(total_amount) as revenue from rclean group by month),
monthly_growth as(
select month, revenue, lag(revenue) over( order by month)
as next_month_revenue from monthly_sales)
select month, revenue, next_month_revenue, 
round(((next_month_revenue-revenue)/revenue)*100,2) as forecasted_growth
from monthly_growth;

#HIGHEST SPENIDNG CUSTOMER IN EACH REGION
with ranked as(
select o.region as region, 
c.customer_id  as customer_id, 
sum(o.total_amount) as revenue,
row_number() over(
partition by o.region order by sum(o.total_amount) desc) as rn
from customers c join orders o
on c.customer_id=o.customer_id
group by o.region, c.customer_id)
select * from ranked where rn<=1;

#CUSTOMER SEGREGATION: CASE
select customer_id, sum(total_amount) spending,
case
when sum(total_amount)>5000 then 'VIP'
when sum(total_amount)>2500 then 'PREMIUM'
else 'Regular'
end as customer_segment
from rclean group by customer_id;

#DIVIDE CUSTOMERS INTO FOUR SPENDING GROUPS
with customer_spending as(
select customer_id, sum(total_amount) spending from rclean
group by customer_id)
select customer_id, spending, ntile(4) over(order by spending desc) as spending_quartile
from customer_spending;

#PERCENTILE OF EACH CUSTOMER
with customer_spending as(
select customer_id, sum(total_amount) spending from rclean
group by customer_id)
select customer_id, spending, percent_rank() over(order by 
spending desc) as spending_percentile from customer_spending;

#PERCENTAGE OF CUSTOMERS SPENDING LESS THAN OR EQUAL TO EACH CUSTOMER
with customer_spending as(
select customer_id, sum(total_amount) spending from rclean
group by customer_id)
select customer_id, spending, cume_dist() over(order by 
spending desc) as cumulative_distribution from customer_spending;

#Which month had the highest revenue?
with sales as(
select date_format(order_date, '%Y-%m') month, sum(total_amount) revenue
from rclean group by month)
select month, revenue,
first_value(month) over(order by revenue desc) as best_month
from sales;

#Which month had the worst revenue?
with sales as(
select date_format(order_date, '%Y-%m') month, sum(total_amount) revenue
from rclean group by month)
select month, revenue,
last_value(month) over(order by revenue desc
rows between unbounded preceding and unbounded following
) as worst_month
from sales;

#Which products perform above their category average revenue?
select product_id, category, sum(total_amount) revenue
from rclean r1 group by product_id, category
having sum(total_amount)>(
select avg(category_revenue) from (select sum(total_amount)
category_revenue from rclean r2
where r1.category=r2.category group by product_id)t );

#EXISTS: At least one order
select distinct customer_id from rclean r1 
where exists (
select * from rclean r2 
where r2.customer_id=r1.customer_id
and returned ='Yes');

#Not exists
select distinct customer_id from rclean r1
where not exists (
select * from rclean r2 where 
r2.customer_id=r1.customer_id and returned='Yes');

#RANK CUSTOMERS AND ASSIGN LOYALTY LEVELS
with cust_spending as(
select customer_id, sum(total_amount) spending
from rclean group by customer_id)
select customer_id, spending, dense_rank() over(
order by spending desc) as spending_rank,
case
when spending>=5000 then 'PLATINUM'
when spending>=3000 then 'GOLD'
when spending>=1000 then 'SILVER'
else 'BRONZE'
end as loyalty_level 
from cust_spending;

#PARETO ANALYSIS
with product_sales as(
select product_id, sum(total_amount) as revenue from rclean group by
product_id),
pareto as(
select product_id, revenue, sum(revenue) over(order by revenue desc)
 as cumulative_revenue,sum(revenue) over() as total_revenue
 from product_sales),
result as(
select product_id, revenue, cumulative_revenue,
round(cumulative_revenue/total_revenue*100,2) as cumulative_percentage
from pareto)
select * from result where cumulative_percentage<=80
order by revenue desc;
