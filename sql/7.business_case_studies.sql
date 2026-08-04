#Which categories generate high revenue but have low sales volume?
select category, sum(total_amount) as revenue, sum(quantity) as sales,
round(sum(total_amount)/sum(quantity),2) as revenue_per_unit
from rclean 
group by category 
order by revenue_per_unit desc;
/* 
KEY FINDINGS (High Revenue / Low Volume):
1. Electronics is the primary High-Revenue / Low-Volume driver:
   - Contributes ~56% of total revenue ($3.32M) at an average unit price of $355.26.
   - Generates 7x more revenue than Fashion despite selling a similar number of units (~9.3k).
2. Home ranks second with $1.08M in revenue at a $130.96 price point.
3. Conclusion: Revenue growth across categories is heavily driven by Price Point (Revenue/Unit) 
   rather than sales volume, as unit sales remain relatively flat (~6k-9k units) across all categories.
*/

#Are higher discounts actually increasing revenue?
select
case
when discount<0.10 then '0-10%'
when discount<0.20 then '10-20%'
when discount<0.30 then '20-30%'
else '30+%'
end as discount_bucket,
count(*) as total_orders,
round(avg(total_amount),2) as avg_order_val,
round(avg(quantity),1) as avg_units_per_order,
sum(quantity) as total_units_sold,
round(sum(total_amount),2) as revenue 
from rclean
group by case
when discount<0.10 then '0-10%'
when discount<0.20 then '10-20%'
when discount<0.30 then '20-30%'
else '30+%' end
order by case
when discount<0.10 then '0-10%'
when discount<0.20 then '10-20%'
when discount<0.30 then '20-30%'
else '30+%' end;
/* 
INTERPRETATION:
- Basket size remains flat at 1.5 units across all discount tiers.
- Higher discounts erode AOV by 24.5% ($175.63 down to $132.53).
- Deep discounts (30%+) drive only 1.6% of overall revenue.

RECOMMENDATION:
- Cap unconditional discounts at 10%.
- Switch to threshold offers (e.g., "Spend $200, Get 15% Off") to force basket growth.
*/

# Is slow shipping leading to high return rates?
select region, round(avg(delivery_time_days),2) as avg_delivery_time,
round(avg(returned='Yes')*100,2) as return_rate
from rclean
group by region
order by return_rate desc,
avg_delivery_time desc;
/* 
INTERPRETATION (Delivery Times vs. Return Rates):
1. Worst Region: East suffers from both the slowest delivery time (5.99 days) 
   and the highest return rate (5.91%).
2. Best Region: Central performs best with fast fulfillment (4.01 days) 
   and the lowest return rate (5.10%).
3. Insight: There is a direct positive correlation between delivery delays and return rates 
   across all 5 regions.

RECOMMENDATION:
- Investigate fulfillment center bottleneck and logistics partners in the East region.
- Target reducing East shipping times to ~4 days to lower return volume.
*/

#Which customers should be enrolled in a customer loyalty program?
with customer_summary as(
select customer_id,
count(order_id) as total_orders, 
round(sum(total_amount),2) as total_spending,
round(avg(total_amount),2) as avg_order_value
from rclean
group by customer_id)
select customer_id, 
total_orders, total_spending, avg_order_value,
case
when total_spending>5000 and total_orders>=10 then 'PREMIUM: VIP CUSTOMERS'
when total_spending>5000 then 'GOLD: HIGH SPENDERS'
when total_orders>=10 then 'SILVER: FREQUENT BUYERS'
end as loyalty_segment
from customer_summary
where total_spending>5000 or total_orders>=10
order by total_spending desc;
/*
LOYALTY PROGRAM SEGMENTATION FINDINGS:
1. Premium VIPs (6 Customers): Both High Spend (>$5k) & High Frequency (>=10 Orders).
   - Top Performer: C16655 ($13,885.10 total spend, $1,388.51 AOV).
   - Action: Provide personal account manager and exclusive perks.

2. Gold High Spenders (23 Customers): Spend >$5k with <10 orders.
   - High AOV buyers (e.g., C15379 at $3,791.86/order).
   - Action: Re-engagement campaigns to increase purchase frequency.

3. Silver Frequent Buyers (102 Customers): >=10 orders with spend <=$5k.
   - Highly loyal buyers with smaller basket sizes (AOV drops down to $36.24).
   - Action: Target with tier-based thresholds to increase Average Order Value (AOV).
*/

#Which payment methods generate the highest profit margin?
select payment_method,
count(*) total_orders,
round(sum(total_amount),2) total_revenue,
round(avg(total_amount*(profit_margin/100)),2) estimate_profit,
round(avg(total_amount*(profit_margin/100))/sum(total_amount)*100,2) weighted_profit
from rclean
group by payment_method 
order by weighted_profit desc;
/*
INTERPRETATION (Payment Method Profitability):
1. Highest Margin Percentage: Wallet (0.05%) and PayPal (0.04%) yield the highest profit margins.
2. Revenue Driver vs Margin: Credit Card drives ~35% of total revenue ($2.05M) but yields 
   the lowest margin (0.01%), likely due to higher payment gateway/processing fees.
3. Highest Profit Dollars: Debit Card generates the highest total profit dollars ($239.72) 
   at a steady 0.02% margin on $1.46M revenue.

RECOMMENDATION:
- Incentivize customers to use low-fee digital methods (Wallet, UPI, PayPal) at checkout 
  to improve net margins on large transactions.
*/

#Which age groups generate the most revenue?
select
case
when customer_age<25 then '18-24'
when customer_age<35 then '25-34'
when customer_age<45 then '35-44'
else '45+'
end as age_group,
round(sum(total_amount),2) total_revenue,
count(distinct customer_id) as total_customers,
round(sum(total_amount)/count(distinct customer_id),2) avg_revenue_per_cust
from rclean
group by age_group order by total_revenue desc;
/*
INTERPRETATION (Revenue by Age Group):
1. Primary Driver: The 45+ age group drives ~47% of total revenue ($2.76M) 
   and has the highest average spend per customer ($392.34 vs ~$245 for under 45).
2. Uniform Middle Tiers: 25-34 and 35-44 cohorts exhibit nearly identical spend patterns 
   (~4.5k customers each, ~$250 spend/customer).
3. Youngest Tier: 18-24 generates the lowest overall revenue ($816.4k) and lowest ARPU ($235.62).

RECOMMENDATION:
- Allocate primary acquisition ad budget toward 45+ demographics with premium/high-ticket products.
- Cross-sell/upsell high-value categories (Electronics, Home) to the 45+ cohort to capitalize on higher purchasing power.
*/

#Which categories have high return rates?
select p.category,
count(*) as total_orders,
sum(o.returned='Yes') as returned_orders,
round(avg(o.returned='Yes')*100,2) as return_rate
from products p join orders o
on p.product_id=o.product_id
group by p.category
order by return_rate desc;
/*
INTERPRETATION (Return Rates by Category):
1. Top Offenders: Fashion (8.28%) and Electronics (7.30%) exhibit the highest return rates 
   and combine to account for >50% of all customer returns.
2. Store Baseline: Home (5.65%), Toys (4.94%), and Sports (4.94%) align with normal baseline returns.
3. Best Performers: Grocery (1.31%) and Beauty (3.78%) experience minimal returns.

RECOMMENDATION:
- Fashion: Improve sizing guides and add customer fit feedback to reduce size-related returns.
- Electronics: Review packaging protection during transit and enhance pre-purchase compatibility info.
*/

#Which regions generate the highest average revenue per customer?
select region,
count(distinct customer_id) as total_customers,
round(sum(total_amount),2) total_revenue,
round(sum(total_amount)/count(distinct customer_id),2)
as revenue_per_customer
from rclean group by region
order by revenue_per_customer;
/*
INTERPRETATION (Regional Revenue per Customer):
1. Top Performer: The South region leads in both total revenue ($1.30M) and average revenue 
   per customer ($263.57).
2. Tight Regional Range: West ($261.14), North ($260.84), and East ($257.52) show consistent 
   customer spend patterns within ~$6 of each other.
3. Opportunity Area: Central lags behind all other regions in both customer count (4,047) 
   and average spend ($232.40 per customer).

RECOMMENDATION:
- Targeted regional promotions or loyalty initiatives in Central to boost average order value 
  up to the ~$260 store baseline.
*/

#Which months experienced the highest and lowest sales?
with monthly_sales as(
select date_format(order_date, '%Y-%m') month,
count(order_id) total_orders,
round(sum(total_amount),2) revenue
from rclean
group by month)
select month,total_orders, revenue,
rank() over(order by revenue desc) as revenue_rank
from monthly_sales
order by revenue_rank asc;
/*
INTERPRETATION (Monthly Sales Trends):
1. Peak Performance: December 2024 (2024-12) achieved the highest overall monthly revenue 
   at $278,154.19 across 1,469 orders.
2. Lowest Full Month: August 2024 (2024-08) recorded the lowest revenue for a full month 
   at $212,613.20 (~23.5% lower than peak December).
3. Partial Data Warning: September 2023 ($151.1k) and September 2025 ($91.8k) rank lowest 
   due to partial month data boundaries rather than operational underperformance.
*/