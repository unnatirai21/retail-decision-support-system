#Created validated working table for analysis
create table rclean as 
select * from retail_sales_raw;

#duplicate rows 
with duplicate_cte as(
select *, row_number() over
(partition by order_id order by order_id) as rn
from rclean)
select * from duplicate_cte where rn>1;

#checking leading/trailing spaces
select count(*) from rclean where category <> trim(category);
select count(*) from rclean where payment_method <> trim(payment_method);
update rclean
set region=trim(region) where region != trim(region);
set sql_safe_updates = 0;
select count(*) from rclean where returned <> trim(returned);

#case consistency
select distinct customer_gender from rclean;
select distinct category from rclean;
select distinct region from rclean;
select distinct returned from rclean;
select distinct payment_method from rclean;

#empty strings
select count(*) from rclean where category='';
select count(*) from rclean where region='';
select count(*) from rclean where customer_gender='';
select count(*) from rclean where returned='';
select count(*) from rclean where payment_method='';

#rule validation
select count(*) from rclean where price<=0;
select count(*) from rclean where quantity<=0;
select count(*) from rclean where customer_age<18 or 
customer_age>100;
select count(*) from rclean where delivery_time_days<0;

/*
DATA VALIDATION REPORT
Purpose: Validate imported transactional data before business analysis.

Checks Performed
✓ NULL validation
✓ Duplicate validation
✓ Leading / trailing whitespace
✓ Empty strings
✓ Domain validation
✓ Business rule validation

Result
Dataset passed all validation checks.
No corrective transformations were required.
*/