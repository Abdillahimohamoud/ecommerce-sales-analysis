-- 1. Total Revenue per Customer
select c.customer_name, sum(p.price * s.quantity) as total_value
from customers c
join sales s
on c.customer_id = s.customer_id
join products p
on s.product_id = p.product_id
group by c.customer_name;


-- 2: Total Revenue per Product
select p.product_name, sum(p.price * s.quantity) as total_revenue
from products p
join sales s
on s.product_id = p.product_id
group by product_name;

-- Task 3: Top 5 Customers by Revenue

select c.customer_id, c.customer_name,  sum(p.price * s.quantity) as total_value
from customers c
join sales s
on c.customer_id = s.customer_id
join products p
on s.product_id = p.product_id
group by c.customer_id, c.customer_name
order by total_value desc
limit 5;

-- Task 4: Top 3 Products by Revenue

select p.product_id, p.product_name, sum(p.price * s.quantity) as total_revenue
from products p
join sales s
on s.product_id = p.product_id
group by p.product_id, p.product_name
order by total_revenue desc
limit 3;

-- Task 5: Total Orders per Region

select r.region_name, count(s.sales_id) as total_orders
from sales s
join customers c
on c.customer_id = s.customer_id
join regions r
on c.region_id = r.region_id
group by r.region_name
order by total_orders desc;


-- Task 6: Average Order Value
select sum(p.price * s.quantity) / count(distinct s.sales_id) as  avg_order_value
from sales s
join products p
on s.product_id = p.product_id;


-- Project 2 — 
-- Task 1 Customer Segmentation

SELECT 
    c.customer_id,
    c.customer_name,
    SUM(s.quantity * p.price) AS total_revenue,
    CASE
        WHEN SUM(s.quantity * p.price) > 1000 THEN 'High Value'
        WHEN SUM(s.quantity * p.price) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM sales s 
JOIN customers c ON s.customer_id = c.customer_id
JOIN products p ON s.product_id = p.product_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_revenue DESC;


-- Task 2: Repeat vs One-Time Customers

select
     c.customer_id, c.customer_name,
     count(s.sales_id) as total_orders,
     case
     when count(s.sales_id) >1 then  'repeated'
     when count(s.sales_id) = 1 then 'one_time_customer'
     end as customer_type
     
from customers c
join sales s
on c.customer_id = s.customer_id
group by c.customer_id, c.customer_name
order by total_orders;


-- Task 3: Most Profitable Products
select
    p.product_id, p.product_name,
    sum(s.quantity * p.price) * 0.2 as total_profit
    from products p
    join sales s
    on p.product_id = s.product_id
    group by p.product_id, product_name
    order by total_profit desc
    limit 5;


-- Task 4: Revenue Contribution per Category (%)

	
WITH category_revenue AS (
    SELECT 
        p.category,
        SUM(p.price * s.quantity) AS total_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY p.category
)

SELECT 
    category,
    total_revenue,
    ROUND(
        total_revenue * 100.0 / SUM(total_revenue) OVER(),
        2
    ) AS percentage_contribution
FROM category_revenue
ORDER BY total_revenue DESC;

-- Task 5: Top Product in Each Category
with product_revenue as
 (select 
     p.category, 
     p.product_name,
      sum(s.quantity * p.price) as total_revenue
from sales s 
join products p
 on s.product_id = p.product_id
 group by p.category, p.product_name
 ), 
 ranked_products as( select*,
 row_number() over (partition by category
 order by total_revenue desc
 ) as rn
 from product_revenue
 )
SELECT 
    category,
    product_name,
    total_revenue
FROM ranked_products
WHERE rn = 1; 

-- Task 6: Customers with Above-Average Spending
with customer_revenue as(
select c.customer_name, sum(s.quantity * p.price) as total_revenue
from sales s 
join customers c 
    on c.customer_id = s.customer_id
join products p 
	on p.product_id = s.product_id
group by c.customer_name
)
select customer_name,
	  total_revenue
from customer_revenue
where total_revenue > (
select avg(total_revenue)
from customer_revenue) 
order by total_revenue desc
;

-- Project 3:
-- TASK 1: Monthly Revenue Trend 

SELECT 
    DATE_TRUNC('month', s.sales_date) AS month,
    SUM(s.quantity * p.price) AS total_revenue
FROM sales s 
JOIN products p ON s.product_id = p.product_id
GROUP BY DATE_TRUNC('month', s.sales_date)
ORDER BY month;

-- Task 2: Monthly Growth Rate
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', s.sales_date) AS month,
        SUM(p.price * s.quantity) AS total_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY DATE_TRUNC('month', s.sales_date)
)

SELECT 
    month,
    total_revenue,

    LAG(total_revenue) OVER (ORDER BY month) AS previous_month_revenue,

    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY month)) 
        * 100.0 
        / LAG(total_revenue) OVER (ORDER BY month),
        2
    ) AS growth_rate_percentage

FROM monthly_revenue
ORDER BY month;

-- Task 3: Running Total Revenue

        WITH daily_revenue AS (
    SELECT 
        DATE_TRUNC('day', s.sales_date) AS sales_date,
        SUM(p.price * s.quantity) AS daily_revenue
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY DATE_TRUNC('day', s.sales_date)
)

SELECT 
    sales_date,
    daily_revenue,
    SUM(daily_revenue) OVER (
        ORDER BY sales_date
    ) AS cumulative_revenue
FROM daily_revenue
ORDER BY sales_date;


-- Final Task (Project 3 Completion)
-- Task 4: Detect Sales Drop (Month-to-Month Decline)

WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', sales_date) AS month,
        SUM(p.price * s.quantity) AS total_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY DATE_TRUNC('month', sales_date)
)

SELECT 
    month,
    total_revenue, 
    LAG(total_revenue) OVER (
        ORDER BY month
    ) AS previous_month_revenue,

    CASE 
        WHEN total_revenue > LAG(total_revenue) OVER (ORDER BY month)
            THEN 'Increase'
        WHEN total_revenue < LAG(total_revenue) OVER (ORDER BY month)
            THEN 'Decrease'
        ELSE 'No Change'
    END AS change_flag

FROM monthly_revenue
ORDER BY month;
