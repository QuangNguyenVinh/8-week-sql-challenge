-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT(to_char(week_date, 'Day')) as day_used
FROM clean_weekly_sales;
-- 2. What range of week numbers are missing from the dataset?

WITH RECURSIVE weeks(current_week) AS
    (
        SELECT 1 UNION ALL SELECT current_week + 1
        FROM weeks
        WHERE current_week < 53
    )
SELECT current_week
FROM weeks
WHERE current_week NOT IN
      (
        SELECT DISTINCT week_number
        FROM clean_weekly_sales
    );

-- 3. How many total transactions were there for each year in the dataset?
SELECT calender_year, COUNT(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calender_year
ORDER BY 1;

-- 4. What is the total sales for each region for each month?
SELECT region, month_number, SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY 1, 2;

-- 5. What is the total count of transactions for each platform?
SELECT platform, SUM(transactions) as total_transactions
FROM clean_weekly_sales
GROUP BY platform
ORDER BY platform;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
WITH sales AS(
    SELECT
        calender_year,
        month_number,
        SUM(CASE WHEN platform = 'Retail' THEN sales END) AS retail_sales,
        SUM(CASE WHEN platform = 'Shopify' THEN sales END) AS shopify_sales,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    GROUP BY calender_year, month_number
)
SELECT calender_year,
       month_number,
       ROUND((sales.retail_sales * 100.0 / sales.total_sales), 2) AS retail_percentage,
       ROUND((sales.shopify_sales * 100.0 / sales.total_sales), 2) AS shopify_percentage
FROM sales
ORDER BY 1, 2;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
WITH demographic_sales AS
    (
        SELECT calender_year,
           SUM(CASE WHEN demographic = 'Couples' THEN sales END) AS couples_sales,
           SUM(CASE WHEN demographic = 'Families' THEN sales END) AS families_sales,
           SUM(CASE WHEN demographic = 'unknown' THEN sales END) AS unknown_sales,
           SUM(sales) AS total_sales
         FROM clean_weekly_sales
         GROUP BY calender_year
     )
SELECT calender_year,
    ROUND((couples_sales * 100.0 / total_sales), 2) AS couples_percentage,
    ROUND((families_sales * 100.0 / total_sales), 2) AS families_percentage,
    ROUND((unknown_sales * 100.0 / total_sales), 2) AS uknown_percentage
FROM demographic_sales
ORDER BY 1;

-- 8. Which age_band and demographic values contribute the most to Retail sales?
SELECT demographic,
       age_band,
       SUM(sales) as total_sales,
       ROUND((SUM(sales) * 100.0) /
             (SELECT SUM(sales)
              FROM clean_weekly_sales
              WHERE platform = 'Retail')
       , 2) AS percentage
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY 3 DESC;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify?
-- If not - how would you calculate it instead?
WITH txn AS(
    SELECT calender_year,
           SUM(CASE WHEN platform = 'Retail' THEN transactions END) AS total_retail_txn,
           SUM(CASE WHEN platform = 'Shopify' THEN transactions END) AS total_shopify_txn,
           SUM(CASE WHEN platform = 'Retail' THEN sales END) AS total_retail_sales,
           SUM(CASE WHEN platform = 'Shopify' THEN sales END) AS total_shopify_sales
    FROM clean_weekly_sales
    GROUP BY calender_year
)
SELECT calender_year,
       ROUND(AVG(total_retail_sales * 100.0 / total_retail_txn), 2) AS avg_retail_txn,
       ROUND(AVG(total_shopify_sales * 100.0 / total_shopify_txn), 2) AS avg_shopify_txn
FROM txn
GROUP BY calender_year
ORDER BY 1;