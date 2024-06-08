SET search_path = data_bank;

-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT r.region_name, COUNT(node_id) AS nodes
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;

-- 3. How many customers are allocated to each region?
SELECT r.region_name, COUNT(DISTINCT customer_id) AS customers
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;

-- 4. How many days on average are customers reallocated to a different node?
SELECT AVG(ABS(start_date - end_date)) AS avg_number_of_day
FROM customer_nodes
WHERE end_date != '9999-12-31';

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH date_diff AS (
    SELECT
        cn.customer_id,
        cn.region_id,
        r.region_name,
        ABS(start_date - end_date) AS reallocation_days
    FROM
        customer_nodes cn
    JOIN
        regions r ON cn.region_id = r.region_id
    WHERE
        end_date != '9999-12-31'
),
     percentiles AS (
         SELECT
             region_name,
             PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY reallocation_days) AS median,
             PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY reallocation_days) AS percentile_80,
             PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY reallocation_days) AS percentile_95
         FROM
             date_diff
         GROUP BY
             region_name
     )
SELECT
    DISTINCT cn.region_id,
             r.region_name,
             p.median,
             p.percentile_80,
             p.percentile_95
FROM
    customer_nodes cn
JOIN
    regions r ON cn.region_id = r.region_id
JOIN
    percentiles p ON r.region_name = p.region_name
WHERE
    cn.end_date != '9999-12-31'
ORDER BY
    r.region_name;
