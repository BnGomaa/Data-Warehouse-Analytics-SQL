# 📊 Data Warehouse Analytics & Advanced SQL Reporting

## 📌 Project Overview
This project demonstrates advanced **SQL Analytics Engineering** skills by transforming raw data from a **Data Warehouse (Gold Layer)** into actionable business insights.

The script goes beyond simple data extraction; it builds **reusable analytical assets (SQL Views)** that automate the calculation of complex metrics like **Customer Lifecycle**, **Product Performance**, and **RFM-based Segmentation**.

## 🛠️ Technical Skills Demonstrated
* **Advanced SQL Scripting:** Utilization of **CTEs (Common Table Expressions)** to structure complex queries and perform multi-step aggregations.
* **Business Logic Implementation:** translating business rules into SQL `CASE` statements to segment customers (VIP vs. Regular) and products (High vs. Low Performers).
* **Data Profiling:** Investigating data quality, date ranges, and distribution before analysis.
* **Metric Engineering:** Calculating advanced KPIs such as **Average Order Value (AOV)**, **Recency**, **Lifespan**, and **Avg Monthly Spend**.
* **View Creation:** Designing persistent views (`gold.report_customers`, `gold.product_Report`) to serve as a clean data source for BI tools (Power BI / Tableau).

## 📂 Project Structure & Analysis Workflow

### 1. Database Exploration & Profiling
* **Objective:** Understand the dataset structure and quality.
* **Actions:** Checked schema metadata, calculated date ranges (Sales Duration), and analyzed customer age distribution.

### 2. Consolidated KPI Reporting
* **Objective:** Create a "One-View" summary of the business.
* **Technique:** Used `UNION ALL` to aggregate disparate metrics (Total Sales, Orders, Quantity, Customers) into a single result set.

### 3. Dimensional Analysis
* **Objective:** Breakdown performance by key business dimensions.
* **Insights:** Analyzed Sales by **Country**, **Category**, and **Gender**.

### 4. Advanced Ranking
* **Objective:** Identify the best and worst performers.
* **Technique:** Used `TOP (N)` with `ORDER BY` to find the top revenue-generating products and customers.

### 5. Analytical Views (The Core Intelligence) 🧠
This is the most advanced part of the project, where raw data is transformed into analytical models.

#### 👤 Customer Report View (`gold.report_customers`)
A 360-degree view of the customer, including:
* **Demographics:** Calculated `Age` and grouped customers into `Age Groups`.
* **Segmentation Logic:**
    * **VIP:** Customers with 12+ months lifespan AND > $5,000 sales.
    * **Regular:** Customers with 12+ months lifespan BUT <= $5,000 sales.
    * **New:** Customers with < 12 months lifespan.
* **Advanced Metrics:** Calculated `Recency` (Months since last order) and `Average Monthly Spend`.

#### 📦 Product Report View (`gold.product_Report`)
A performance scorecard for every product, featuring:
* **Performance Segmentation:** Classified products into **High-Performers**, **Mid-Range**, and **Low-Performers** based on revenue thresholds.
* **Pricing Analysis:** Calculated `Avg Selling Price` handling division-by-zero errors.
* **Sales Metrics:** `Average Order Revenue (AOR)` and `Product Lifespan`.

## 🚀 How to Use
1.  Open the SQL script `Data_Warehouse_Analytics.sql` in **SQL Server Management Studio (SSMS)**.
2.  Execute the script sections sequentially to view the analysis.
3.  To use the created reports, run the following queries after execution:
    ```sql
    -- Get all VIP Customers
    SELECT * FROM gold.report_customers WHERE Customer_Segment = 'VIP';

    -- Get High-Performing Products
    SELECT * FROM gold.product_Report WHERE "Product Segment" = 'High-Performers';
    ```
