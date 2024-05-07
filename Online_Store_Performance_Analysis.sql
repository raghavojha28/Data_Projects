## Customer Growth Analysis

/* 1. Calculating average of monthly active users per year */

select year, round(avg(total_customer),0) as avg_active_user
from
(select date_part('year', od.order_purchase_timestamp) as year,
   date_part('month', od.order_purchase_timestamp) as month,
   count(distinct cd.customer_unique_id) as total_customer
from order_dataset as od
join customer_dataset as cd on od.customer_id = cd.customer_id
group by 1,2) a
group by 1;

/* 2. Calculating the number of new customers per year */

select 
 date_part('year', first_time_order) as year, 
 count(a.customer_unique_id) as new_customers 
from (
        select 
   c.customer_unique_id,
            min(o.order_purchase_timestamp) as first_time_order
  from order_dataset o
  inner join customer_dataset c on c.customer_id = o.customer_id
  group by 1
) as a
group by 1
order by 1;

/* 3. Calculating the number of customers who placed a repeat order per year */

select year, count(total_customer) as repear_order
from
(select date_part('year', od.order_purchase_timestamp) as year,
   cd.customer_unique_id,
   count(cd.customer_unique_id) as total_customer,
   count(od.order_id) as total_order
from order_dataset as od
join customer_dataset as cd on od.customer_id = cd.customer_id
group by 1,2
having count(order_id) >1
) a
group by 1
order by 1;

/* 4. Calculating average orders per year */

select year, round(avg(total_order),2) as avg_frequency_order
from
(select date_part('year', od.order_purchase_timestamp) as year,
   cd.customer_unique_id,
   count(distinct order_id) as total_order
from order_dataset as od
join customer_dataset as cd on od.customer_id = cd.customer_id
group by 1,2
) a
group by 1
order by 1;

/* 5. Creating a CTE and combining all previous query results  */

with count_mau as (
select year, round(avg(total_customer),0) as avg_active_user
from
(select date_part('year', od.order_purchase_timestamp) as year,
   date_part('month', od.order_purchase_timestamp) as month,
   count(distinct cd.customer_unique_id) as total_customer
from order_dataset as od
join customer_dataset as cd on od.customer_id = cd.customer_id
group by 1,2) a
group by 1
),

count_newcust as(
select 
 date_part('year', first_time_order) as year, 
 count(a.customer_unique_id) as new_customers 
from (
        select 
   c.customer_unique_id,
            min(o.order_purchase_timestamp) as first_time_order
  from order_dataset o
  inner join customer_dataset c on c.customer_id = o.customer_id
  group by 1
) a
group by 1
order by 1
),

count_repeat_order as(
select year, count(total_customer) as repeat_order
from
(select date_part('year', od.order_purchase_timestamp) as year,
   cd.customer_unique_id,
   count(cd.customer_unique_id) as total_customer,
   count(od.order_id) as total_order
from order_dataset as od
join customer_dataset as cd on od.customer_id = cd.customer_id
group by 1,2
having count(order_id) >1
) a
group by 1
order by 1
),

avg_order as (
select year, round(avg(total_order),2) as avg_frequency_order
from
(select date_part('year', od.order_purchase_timestamp) as year,
   cd.customer_unique_id,
   count(distinct order_id) as total_order
from order_dataset as od
join customer_dataset as cd on od.customer_id = cd.customer_id
group by 1,2
) a
group by 1
order by 1)

select 
cm.year,
cm.avg_active_user,
cn.new_customers,
cro.repeat_order,
ao.avg_frequency_order
from count_mau cm 
join count_newcust cn on cm.year=cn.year
join count_repeat_order cro on cm.year=cro.year
join avg_order ao on cm.year=ao.year;


# Conclusion: With the increase in New customers, the avg Monthly Active Users are also increasing.    




## Product Category Analysis Based on total revenue and total product cancelations

/* Calculating total revenue per year */

create table total_revenue_per_year as
select 
 date_part('year', o.order_purchase_timestamp) as year,
 sum(revenue_per_order) as revenue
from (
 select 
  order_id, 
  sum(price+freight_value) as revenue_per_order
 from order_items_dataset
 group by 1
) subq
join order_dataset o on subq.order_id = o.order_id
where o.order_status = 'delivered'
group by 1
order by 1

/* Calculating total canceled orders per year */

CREATE TABLE total_cancel_order_per_year AS
SELECT
 date_part('year',order_purchase_timestamp) as year,
 COUNT(o.order_id) AS total_cancel
FROM order_dataset as o
WHERE order_status = 'canceled'
GROUP BY 1
ORDER BY 1

/* Calculating highest total revenues per product category per year */ 

create table top_product_category_by_revenue_per_year as 
select year, product_category_name, revenue 
from (
 select 
  date_part('year', o.order_purchase_timestamp) as year,
  p.product_category_name as product_cat,
  sum(oi.price + oi.freight_value) as revenue,
  rank() over(
   partition by date_part('year', o.order_purchase_timestamp) 
  order by 
 sum(oi.price + oi.freight_value) desc) as rk
 from order_items_dataset oi
 join order_dataset o on o.order_id = oi.order_id
 join product_dataset p on p.product_id = oi.product_id
 where o.order_status = 'delivered'
 group by 1,2
) sq
where rk = 1;

/* Calculating highest canceled order per product category per year */

create table top_product_category_by_cancel_per_year as 
select year, product_category_name, total_cancel 
from (
 select 
  date_part('year', o.order_purchase_timestamp) as year,
  p.product_category_name as product_cat,
  count(o.order_id) as total_cancel,
  rank() over(
   partition by date_part('year', o.order_purchase_timestamp) 
  order by 
 count(o.order_id) desc) as rk
 from order_items_dataset oi
 join order_dataset o on o.order_id = oi.order_id
 join product_dataset p on p.product_id = oi.product_id
 where o.order_status = 'canceled'
 group by 1,2
) sq
where rk = 1;


/* Creating a new table which contain all the above tables */

select 
tpy.year AS year, 
tpy.product_category_name AS top_product_category_by_revenue,
tpy.revenue AS category_revenue, 
tr.revenue AS year_total_revenue,
tcy.product_category_name AS most_canceled_product_category,
tcy.total_cancel AS category_num_canceled,
tco.total_cancel AS year_total_num_canceled
from top_product_category_by_revenue_per_year tpy
join total_revenue_per_year tr on tpy.year = tr.year
join top_product_category_by_cancel_per_year tcy on tpy.year = tcy.year
join total_cancel_order_per_year tco on tpy.year = tco.year


## Conclusion: "Health & Beauty" was the most cancelled product category but also the best selling product category