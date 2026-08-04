#BASIC BUSINESS KPI\\
#total revenue
select round(sum(total_amount),2) as total_revenue from rclean;

#total orders
select count(order_id) as total_orders from rclean;

#avg order val
select round(avg(total_amount),2) as avg_order_val from rclean;

#total customers
select count(distinct customer_id) from rclean;

#total_product
select count(distinct product_id) from rclean;

#CATGEGORY ANALYSIS\\
#1.revenue by category
select category, 
round(sum(total_amount),2) as revenue from rclean
group by category order by revenue desc;

#2. orders by category
select category, count(order_id) as total_orders from rclean group by
category order by count(order_id) desc;

#avg order value by category
select category, round(avg(total_amount),2) as avg_order from rclean
group by category order by avg_order desc;

#highest discount in each category
select category, round(avg(discount)*100,2) as avg_disc from rclean
group by category order by avg_disc DESC;

#CUSTOMER ANALYSIS\\
#Revenue by Gender
select c.customer_gender as customer_gender, 
round(sum(o.total_amount),2) as revenue from customers c
join orders o
on c.customer_id=o.customer_id
group by c.customer_gender;

#avg spend by gender
select customer_gender, round(avg(total_amount),2) as revenue from rclean
group by customer_gender;

#age group analysis
select case
when c.customer_age<25 then '18-24'
when c.customer_age<35 then '25-34'
when c.customer_age<45 then '35-44'
when c.customer_age<55 then '45-54'
else '55+'
end age_group, 
round(sum(o.total_amount),2) revenue
from customers c
join orders o
on c.customer_id=o.customer_id
group by age_group order by revenue desc;

#REGIONAL ANALYSIS
#Revenue by Region
select region, round(sum(total_amount),2) revenue
from rclean group by region order by revenue desc;

#Return Rate by Region
select region, round(avg(returned='Yes')*100,2) as return_rate
from rclean group by region order by return_rate desc;

#PAYMENT ANALYSIS
#Revenue by Payment Method
select payment_method, round(sum(total_amount),2) revenue
from rclean group by payment_method;

#Avg Discount by Payment Method
select payment_method, round(avg(discount)*100,2)
from rclean group by payment_method;