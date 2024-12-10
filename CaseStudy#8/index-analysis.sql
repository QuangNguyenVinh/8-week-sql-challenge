-- The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
-- Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.
DROP TABLE IF EXISTS index_table;
WITH cte AS (SELECT *, ROUND((composition / index_value)::numeric, 2) AS avg_composition
             FROM interest_metrics)
SELECT *
INTO index_table
FROM cte;

-- 1. What is the top 10 interests by the average composition for each month?
WITH ranks_tab AS (SELECT i.interest_id,
                          interest_name,
                          month_year,
                          avg_composition,
                          RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) ranks
                   FROM index_table i
                            JOIN interest_map m
                                 ON CAST(i.interest_id AS INT) = m.id)
SELECT *
FROM ranks_tab
WHERE ranks <= 10;

-- 2. For all of these top 10 interests - which interest appears the most often?
WITH ranks_cte AS (SELECT i.interest_id,
                          interest_name,
                          month_year,
                          avg_composition,
                          RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) ranks
                   FROM index_table i
                            JOIN interest_map m
                                 ON CAST(i.interest_id AS INT) = m.id)
SELECT DISTINCT interest_id, interest_name, COUNT(*) OVER (PARTITION BY interest_name) AS counts
FROM ranks_cte
WHERE ranks <= 10
ORDER BY 3 DESC;

-- 3. What is the average of the average composition for the top 10 interests for each month?
WITH ranks_cte AS (SELECT i.interest_id,
                          interest_name,
                          month_year,
                          avg_composition,
                          RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) ranks
                   FROM index_table i
                            JOIN interest_map m
                                 ON CAST(i.interest_id AS INT) = m.id)
SELECT month_year, ROUND(AVG(avg_composition), 2) AS avg_monthly_comp
FROM ranks_cte
WHERE ranks <= 10
GROUP BY month_year;

-- 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
WITH month_comp AS (SELECT month_year, ROUND(MAX(avg_composition), 2) AS max_avg_comp
                    FROM index_table

                    GROUP BY month_year),
     rolling_avg AS (
         SELECT i.month_year,
                interest_id,
                interest_name,
                max_avg_comp                                                                                      AS max_index_composition,
                ROUND(AVG(max_avg_comp) OVER (ORDER BY i.month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
                      2)                                                                                          AS three_month_moving_avg
         FROM index_table i
                  JOIN month_comp m ON i.month_year = m.month_year
                  JOIN interest_map ma
                       ON CAST(i.interest_id AS INT) = ma.id
         WHERE avg_composition = max_avg_comp
     ),
     month_1_lag AS (SELECT *,
                            CONCAT(LAG(interest_name) OVER ( ORDER BY month_year), ' : ',
                                   LAG(max_index_composition) OVER (ORDER BY month_year)) AS one_month_ago
                     FROM rolling_avg),
     month_2_lag AS (SELECT *, LAG(one_month_ago) OVER (ORDER BY month_year) AS two_month_ago
                     FROM month_1_lag)
SELECT *
FROM month_2_lag
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';