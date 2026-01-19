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