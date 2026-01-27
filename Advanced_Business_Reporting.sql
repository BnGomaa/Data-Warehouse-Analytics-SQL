/*
===============================================================================
Project: Data Warehouse Analytics
Description: 
    This script analyzes the 'Gold' schema of the Data Warehouse to generate
    key business metrics and reports. It covers:
    1. Database Exploration (Schema & Data Types).
    2. Data Profiling (Date Ranges, Age Distribution).
    3. Aggregated Business Metrics (Total Sales, Orders, Customers).
    4. Dimension Analysis (Sales by Country, Category, Gender).
    5. Performance Ranking (Top/Bottom Products & Customers).
===============================================================================
*/

-- =============================================================================
-- 1. DATABASE EXPLORATION & PROFILING
-- =============================================================================

-- Explore Tables in the Database
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- Explore Columns in Key Dimensions and Fact Tables
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'dim_customers';
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'dim_products';
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'fact_sales';

-- Explore Data Segments (Countries & Categories)
SELECT DISTINCT country FROM gold.dim_customers;

SELECT DISTINCT 
    category, 
    subcategory, 
    product_name
FROM gold.dim_products
ORDER BY 1, 2, 3;

-- Date Profiling: Range of Sales Data
SELECT 
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) AS order_range_years
FROM gold.fact_sales;

-- Customer Profiling: Age Distribution
SELECT 
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS max_age,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS min_age
FROM gold.dim_customers;


-- =============================================================================
-- 2. KEY PERFORMANCE INDICATORS (KPIs)
-- =============================================================================

/* Consolidated Business Report:
   Using UNION ALL to create a unified view of all high-level metrics 
   (Sales, Quantity, Price, Orders, Products, Customers).
*/

SELECT 'Total Sales' AS Measure_Name, SUM(sales_amount) AS Measure_Value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(product_key) FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(customer_key) FROM gold.dim_customers;


-- =============================================================================
-- 3. DIMENSIONAL ANALYSIS (GROUP BY REPORTS)
-- =============================================================================

-- 3.1 Total Customers by Country
SELECT 
    country, 
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- 3.2 Total Customers by Gender
SELECT 
    gender, 
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- 3.3 Total Products by Category
SELECT 
    category, 
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- 3.4 Average Cost per Category
SELECT 
    category, 
    AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- 3.5 Total Revenue by Category
SELECT 
    p.category, 
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 3.6 Sales Distribution by Country
SELECT 
    c.country, 
    SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c ON f.customer_key = c.customer_key 
GROUP BY c.country
ORDER BY total_sold_items DESC;


-- =============================================================================
-- 4. ADVANCED RANKING (TOP & BOTTOM PERFORMERS)
-- =============================================================================

-- 4.1 Top 5 Revenue-Generating Products
SELECT TOP (5)
    p.product_name, 
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- 4.2 Bottom 5 Worst-Performing Products
SELECT TOP (5)
    p.product_name, 
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;

-- 4.3 Top 10 High-Value Customers
SELECT TOP (10)
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- 4.4 Low-Engagement Customers (Fewest Orders)
SELECT TOP (3)
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders 
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name

ORDER BY total_orders ASC;
-- ===============================================================================
/*
=======================================================================
Customer Report
=======================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
-- ======================================================================
*/
--- =====================================================================
-- 1) Base Query: Retrieves core columns from tables
-- ======================================================================
create view gold.report_customers as  
with base_Query AS 
(
    Select 
    f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(C.first_name,' ' , c.last_name) as Customer_name,
    DATEDIFF(Year,c.birthdate, GETDATE())   as Age            
    from gold.fact_sales as f
    left join gold.dim_customers as c
    on f.customer_key = c.customer_key
    where order_date IS NOT null
) ,

Customer_Aggregations as
(
select 
    customer_key,
    customer_number,
    Customer_name,
    Age,
    count(Distinct order_number) as Total_Orders ,
    Sum (sales_amount) as Total_Sales ,
    Sum (quantity) as Total_QTY ,
    COUNT(distinct product_key) as total_products,
    MAX(order_date) as last_order,
    DATEDIFF(Month,Min(order_date),Max(order_date)) as lifespan
from base_Query
group by 
    customer_key,
    customer_number,
    Customer_name,
    Age
)
    select 
       customer_key,
        customer_number,
        Customer_name,
        Age,
               CASE
            WHEN age < 20 THEN 'Under 20'
            WHEN age between 20 and 29 THEN '20-29'
            WHEN age between 30 and 39 THEN '30-39'
            WHEN age between 40 and 49 THEN '40-49'
            ELSE '50 and above'
        END AS age_group,
        Case
            when lifespan >= 12 and Total_Sales > 5000 then 'VIP'
            when lifespan >= 12 and Total_Sales <= 5000 then 'Regular'
            Else 'New'
        End AS Customer_Segment,
        Total_Orders ,
        Total_Sales ,
        Total_QTY ,
        total_products,
        last_order,
        lifespan,
        DATEDIFF(month, last_order ,Getdate()) as recency,
        CASE 
            when Total_Sales = 0 then 0 
            Else Total_Sales / Total_Orders 
            END as AOV,
        CASE 
             when lifespan = 0 then Total_Sales 
             Else (Total_Sales /lifespan) 
         END as average_monthly_spend       
    from customer_aggregations;
-- ===========================================================================================
/*
==============================================================
-- Product Report
==============================================================

Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Perforers.
    3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue

*/
create view gold.product_Report as
with base_query AS 
(
    select 
    f.order_number,
    f.customer_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
     p.cost
    from gold.fact_sales as f
    left join gold.dim_products as p 
    on f.product_key = p.product_key
    where f.order_date IS NOT NULL
),
product_Aggregations as
(
select 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    count(Distinct order_number) as Total_Orders ,
    Sum (sales_amount) as Total_Sales ,
    Sum (quantity) as Total_QTY,
    Count(Distinct customer_key) as total_customers,
    MAX(order_date) as last_sele,
    DATEDIFF(Month,Min(order_date),Max(order_date)) as lifespan,
    Round(AVG(Cast(sales_amount as float)/nullif(quantity,0)),1) as avg_selling_price

from base_query 
Group By 
    product_key,
    product_name,
    category,
    subcategory,
    cost
)
select 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    Total_Orders ,
    Total_Sales ,
    Total_QTY,
    total_customers,
    last_sele,
    lifespan,
    avg_selling_price,
    Case 
        when Total_Sales > 50000 then 'High-Performers'
        when Total_Sales <= 10000 then 'Mid-Range'
        Else 'Low-Performers'
    End as 'Product Segment',
    DATEDIFF(MONTH, last_sele, GETDATE()) as recency,
    CASE
        when Total_Orders = 0 then 0 
        else Total_Sales / Total_Orders 
    END as AOR,
        CASE
        when lifespan = 0 then Total_Sales
        else Total_Sales / lifespan
    END as 'average monthly revenue' 
    from product_Aggregations
