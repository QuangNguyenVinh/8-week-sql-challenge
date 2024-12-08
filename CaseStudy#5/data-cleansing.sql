CREATE TABLE clean_weekly_sales
(
    week_date DATE,
    week_number INT,
    month_number INT,
    calender_year INT,
    region VARCHAR,
    platform VARCHAR,
    segment VARCHAR,
    age_band VARCHAR,
    demographic VARCHAR,
    transactions INT,
    sales INT,
    avg_transaction FLOAT
);

WITH CTE AS (
    SELECT
        to_date(week_date, 'DD-MM-YY') as week_date,
        date_part('week', to_date(week_date, 'DD-MM-YY')) as week_number,
        date_part('month', to_date(week_date, 'DD-MM-YY')) as month_number,
        date_part('year', to_date(week_date, 'DD-MM-YY')) as calendar_year,
        region,
        platform,
        segment,
        CASE
            WHEN "right"(segment, 1) = '1' THEN 'Young Adults'
            WHEN "right"(segment, 1) = '2' THEN 'Middle Aged'
            WHEN "right"(segment, 1) IN ('3', '4') THEN 'Retirees'
            ELSE 'unknown'
        END AS age_band,
        CASE
            WHEN "left"(segment, 1) = 'F' THEN 'Families'
            WHEN "left"(segment, 1) = 'C' THEN 'Couples'
            ELSE 'unknown'
        END AS demographic,
        customer_type,
        transactions,
        sales,
        ROUND(sales / transactions, 2) AS avg_transactions
    FROM weekly_sales
)
INSERT INTO clean_weekly_sales
    (week_date, week_number, month_number, calender_year, region, platform, segment, age_band, demographic, transactions, sales, avg_transaction)
SELECT week_date,
       week_number,
       month_number,
       calendar_year,
       region,
       platform,
       segment,
       age_band,
       demographic,
       transactions,
       sales,
       avg_transactions
FROM CTE
