-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
DROP TABLE IF EXISTS filtered_table;
WITH cte AS
         (SELECT interest_id, COUNT(DISTINCT month_year) AS month_count
          FROM interest_metrics
          GROUP BY interest_id
          HAVING COUNT(DISTINCT month_year) >= 6)
SELECT *
INTO filtered_table
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM cte);

--Top 10
SELECT month_year,
       interest_id,
       interest_name,
       MAX(composition) AS max_composition
FROM filtered_table f
         JOIN interest_map ma ON
    CAST(f.interest_id AS INT) = ma.id
GROUP BY month_year, interest_id, interest_name
ORDER BY 4 DESC
LIMIT 10;

--Bottom 10

SELECT month_year, interest_id, interest_name, MAX(composition) AS max_composition
FROM filtered_table f
         JOIN interest_map ma ON
    CAST(f.interest_id AS INT) = ma.id
GROUP BY month_year, interest_id, interest_name
ORDER BY 4
LIMIT 10;

-- 2. Which 5 interests had the lowest average ranking value?
SELECT interest_id,
       interest_name,
       AVG(ranking) AS avg_rank
FROM filtered_table f
         JOIN interest_map ma ON
    CAST(f.interest_id AS INT) = ma.id
GROUP BY interest_id, interest_name
ORDER BY 3
LIMIT 5;

-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
SELECT interest_id,
       interest_name,
       ROUND(STDDEV_POP(percentile_ranking)::numeric, 2) AS stdev_ranking
FROM filtered_table f
         JOIN interest_map ma ON CAST(f.interest_id AS INT) = ma.id
GROUP BY interest_id, interest_name
ORDER BY stdev_ranking DESC
LIMIT 5;

-- 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
WITH interests AS
         (SELECT interest_id
               , interest_name
               , ROUND(STDDEV_POP(percentile_ranking)::numeric, 2) AS stdev_ranking
          FROM filtered_table f
                   JOIN interest_map ma ON
              CAST(f.interest_id AS INT) = ma.id
          GROUP BY interest_id, interest_name
          ORDER BY 3 DESC
          LIMIT 5),
     percentiles AS (SELECT i.interest_id,
                            interest_name,
                            MAX(percentile_ranking) AS max_percentile,
                            MIN(percentile_ranking) AS min_percentile
                     FROM filtered_table f
                              JOIN interests i
                                   ON CAST(i.interest_id AS INT) = CAST(f.interest_id AS INT)
                     GROUP BY i.interest_id, interest_name),
     max_per AS
         (SELECT p.interest_id, interest_name, month_year AS max_year, max_percentile
          FROM filtered_table f
                   JOIN percentiles p
                        ON CAST(p.interest_id AS INT) = CAST(f.interest_id AS INT)
          WHERE max_percentile = percentile_ranking),
     min_per AS
         (SELECT p.interest_id, interest_name, month_year AS min_year, min_percentile
          FROM filtered_table f
                   JOIN percentiles p
                        ON CAST(p.interest_id AS INT) = CAST(f.interest_id AS INT)
          WHERE min_percentile = percentile_ranking)

SELECT mi.interest_id, mi.interest_name, min_year, min_percentile, max_year, max_percentile
FROM min_per mi
         JOIN max_per ma ON mi.interest_id = ma.interest_id;

-- 5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?