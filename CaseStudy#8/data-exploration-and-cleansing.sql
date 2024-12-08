-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
ALTER TABLE interest_metrics
    DROP COLUMN month_year;

ALTER TABLE interest_metrics
    ADD month_year date;

UPDATE interest_metrics
SET month_year= TO_DATE(_year || '-' || _month || '-01', 'YYYY-MM-DD');


SELECT *
FROM interest_metrics;

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT month_year, COUNT(*) AS records
FROM interest_metrics
GROUP BY month_year
ORDER BY 1;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
DELETE
FROM interest_metrics
WHERE month_year IS NULL;

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT COUNT(DISTINCT interest_id) ids_not_in_maps
FROM interest_metrics
WHERE interest_id NOT IN (SELECT interest_id FROM interest_map);

SELECT COUNT(id) AS ids_not_in_metrics
FROM interest_map
WHERE id NOT IN (SELECT CAST(interest_id AS INT) FROM interest_metrics);

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT id, interest_name, COUNT(*) AS count
FROM interest_map m
         JOIN interest_metrics me
              ON m.id = CAST(me.interest_id AS INT)
GROUP BY id, interest_name
ORDER BY 3 DESC;

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
SELECT _month,
       _year,
       interest_id,
       composition,
       index_value,
       ranking,
       percentile_ranking,
       month_year,
       interest_name,
       interest_summary,
       created_at,
       last_modified
FROM interest_metrics me
         JOIN interest_map m
              ON CAST(me.interest_id AS INT) = m.id
WHERE CAST(interest_id AS INT) = 21246;

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
SELECT *
FROM interest_metrics me
         JOIN interest_map m
              ON CAST(me.interest_id AS INT) = m.id
WHERE month_year < created_at
  AND interest_id IS NOT NULL;