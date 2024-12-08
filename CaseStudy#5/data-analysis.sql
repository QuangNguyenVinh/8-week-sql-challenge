-- 1. What is the total sales for the 4 weeks before and after 2020-06-15?
-- What is the growth or reduction rate in actual values and percentage of sales?
WITH cte AS(
    SELECT DISTINCT
        ('2020-06-15'::date - interval '4 weeks') as date_before,
        ('2020-06-15'::date + interval '4 weeks') as date_after
    FROM clean_weekly_sales
),
changes AS(
    SELECT *,
           CASE WHEN week_date >= '2020-06-15' THEN 'after' ELSE 'before' END AS check_point
    FROM clean_weekly_sales
    WHERE calender_year = '2020'
),
sales_changes AS(
    SELECT
        SUM(CASE WHEN check_point = 'before' AND week_date >= cte.date_before THEN sales END) AS before_change_total_sales,
        SUM(CASE WHEN check_point = 'after' AND week_date <= cte.date_after THEN sales END) AS after_change_total_sales
    FROM changes, cte
)
SELECT *,
       before_change_total_sales,
       after_change_total_sales,
       after_change_total_sales - before_change_total_sales AS sales_diff,
       ROUND((after_change_total_sales - before_change_total_sales) * 100.0 / before_change_total_sales, 2) AS change_percentage
FROM sales_changes;
-- 2. What about the entire 12 weeks before and after?
WITH cte AS(
    SELECT DISTINCT
        ('2020-06-15'::date - interval '12 weeks') as date_before,
        ('2020-06-15'::date + interval '12 weeks') as date_after
    FROM clean_weekly_sales
),
     changes AS(
         SELECT *,
                CASE WHEN week_date >= '2020-06-15' THEN 'after' ELSE 'before' END AS check_point
         FROM clean_weekly_sales
         WHERE calender_year = '2020'
     ),
     sales_changes AS(
         SELECT
             SUM(CASE WHEN check_point = 'before' AND week_date >= cte.date_before THEN sales END) AS before_change_total_sales,
             SUM(CASE WHEN check_point = 'after' AND week_date <= cte.date_after THEN sales END) AS after_change_total_sales
         FROM changes, cte
     )
SELECT *,
       before_change_total_sales,
       after_change_total_sales,
       after_change_total_sales - before_change_total_sales AS sales_diff,
       ROUND((after_change_total_sales - before_change_total_sales) * 100.0 / before_change_total_sales, 2) AS change_percentage
FROM sales_changes;

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
WITH cte AS(
    SELECT DISTINCT week_number as wn
    FROM clean_weekly_sales
    WHERE week_date = '2020-06-15' AND calender_year = '2020'
),sales AS(
    SELECT calender_year,
           week_number,
           sum(sales) as total_sales
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 21 AND 28
    GROUP BY calender_year, week_number
), changes AS(
     SELECT calender_year,
            SUM(CASE WHEN week_number >= 21 AND week_number < cte.wn THEN total_sales END) AS before_sales,
            SUM(case when week_number >= cte.wn AND week_number <= 28 then total_sales END) AS after_sales
     FROM sales, cte
     GROUP BY calender_year
     )
SELECT calender_year,
       before_sales,
       after_sales,
       (after_sales- before_sales) as sales_diff,
       ((after_sales - before_sales) * 100.0 / before_sales) as diff_percentage
FROM changes;
