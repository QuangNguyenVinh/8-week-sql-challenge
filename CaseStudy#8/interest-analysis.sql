-- 1. Which interests have been present in all month_year dates in our dataset?
SELECT COUNT(DISTINCT month_year) AS count
FROM interest_metrics;

SELECT DISTINCT interest_id
FROM interest_metrics
GROUP BY interest_id
HAVING COUNT(DISTINCT month_year) = 14;

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
WITH months_count AS (SELECT DISTINCT interest_id, COUNT(month_year) AS month_count
                      FROM interest_metrics
                      GROUP BY interest_id)
   , interests_count AS
    (SELECT month_count, COUNT(interest_id) AS interest_count
     FROM months_count
     GROUP BY month_count)
   , cumulative_percentage AS
    (SELECT *,
            ROUND(SUM(interest_count) OVER (ORDER BY month_count DESC) * 100.0 /
                  (SELECT SUM(interest_count) FROM interests_count), 2) AS cumulative_percent
     FROM interests_count
     GROUP BY month_count, interest_count)
SELECT *
FROM cumulative_percentage
WHERE cumulative_percent > 90;

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
WITH cte AS
         (SELECT interest_id, COUNT(DISTINCT month_year) AS month_count
          FROM interest_metrics
          GROUP BY interest_id
          HAVING COUNT(DISTINCT month_year) < 6)

--getting the number of times the above interest ids are present in the interest_metrics table
SELECT COUNT(interest_id) AS interest_record_to_remove
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM cte);

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
WITH cte AS
         (SELECT interest_id, COUNT(DISTINCT month_year) AS month_count
          FROM interest_metrics
          GROUP BY interest_id
          HAVING COUNT(DISTINCT month_year) < 6)
SELECT removed.month_year,
       present_interest,
       removed_interest,
       ROUND(removed_interest * 100.0 / (removed_interest + present_interest), 2) AS removed_percentage
FROM (SELECT month_year, COUNT(*) AS removed_interest
      FROM interest_metrics
      WHERE interest_id IN (SELECT interest_id FROM cte)
      GROUP BY month_year) removed
         JOIN

     (SELECT month_year, COUNT(*) AS present_interest
      FROM interest_metrics
      WHERE interest_id NOT IN (SELECT interest_id FROM cte)
      GROUP BY month_year) present
     ON removed.month_year = present.month_year
ORDER BY removed.month_year;

-- 5. After removing these interests - how many unique interests are there for each month?
WITH cte AS
         (SELECT interest_id, COUNT(DISTINCT month_year) AS month_count
          FROM interest_metrics
          GROUP BY interest_id
          HAVING COUNT(DISTINCT month_year) < 6)
SELECT month_year, COUNT(DISTINCT interest_id) AS unique_present_interest
FROM interest_metrics
WHERE interest_id NOT IN (SELECT interest_id FROM cte)
GROUP BY month_year
ORDER BY 1;