-- 1. What are the top 3 products by total revenue before discount?
SELECT DISTINCT product_name, SUM((qty * s.price) * (1 - discount * 0.01)) AS total_revenue
FROM sales s
         JOIN product_details pd
              ON s.prod_id = pd.product_id
GROUP BY product_name
ORDER BY 2 DESC
OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY;

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT segment_name,
       SUM(qty)                                               AS total_qty,
       ROUND(SUM((qty * s.price) * (1 - discount * 0.01)), 2) AS total_revenue,
       ROUND(SUM(discount * qty * s.price / 100.0), 2)        AS total_disc
FROM sales s
         JOIN product_details pd
              ON s.prod_id = pd.product_id
GROUP BY segment_name;

-- 3. What is the top selling product for each segment?
WITH cte AS
         (SELECT segment_name,
                 product_name,
                 SUM(qty)                                                       AS total_qty,
                 RANK() OVER (PARTITION BY segment_name ORDER BY SUM(qty) DESC) AS rk
          FROM sales s
                   JOIN product_details pd ON s.prod_id = pd.product_id
          GROUP BY segment_name, product_name)
SELECT segment_name, product_name, total_qty
FROM cte
WHERE rk = 1;

-- 4. What is the total quantity, revenue and discount for each category?
SELECT category_name,
       SUM(qty)                                               AS total_qty,
       ROUND(SUM((qty * s.price) * (1 - discount * 0.01)), 2) AS total_revenue,
       ROUND(SUM(discount * qty * s.price / 100.0), 2)        AS total_dis
FROM sales s
         JOIN product_details pd ON s.prod_id = pd.product_id
GROUP BY category_name;

-- 5. What is the top selling product for each category?
WITH cte AS (SELECT category_name,
                    product_name,
                    SUM(qty)                                                        AS total_qty,
                    RANK() OVER (PARTITION BY category_name ORDER BY SUM(qty) DESC) AS rk
             FROM sales s
                      JOIN product_details pd ON s.prod_id = pd.product_id
             GROUP BY category_name, product_name)
SELECT category_name, product_name, total_qty
FROM cte
WHERE rk = 1;

-- 6. What is the percentage split of revenue by product for each segment?
WITH prods AS (SELECT segment_name, product_name, SUM((qty * s.price) * (1 - discount * 0.01)) AS rev_prod
               FROM sales s
                        JOIN product_details pd ON s.prod_id = pd.product_id
               GROUP BY segment_name, product_name)
SELECT segment_name,
       product_name,
       ROUND(rev_prod * 100.0 / (SELECT SUM((qty * price) * (1 - discount * 0.01)) FROM sales), 2) AS rev_percentage
FROM prods
ORDER BY 1, 3;

-- 7. What is the percentage split of revenue by segment for each category?
WITH seg AS
         (SELECT category_name, segment_name, SUM((qty * s.price) * (1 - discount * 0.01)) AS rev_seg
          FROM sales s
                   JOIN product_details pd ON s.prod_id = pd.product_id
          GROUP BY category_name, segment_name)
SELECT category_name,
       segment_name,
       ROUND(rev_seg * 100.0 / (SELECT SUM((qty * price) * (1 - discount * 0.01)) FROM sales), 2) AS rev_seg_percentage
FROM seg
ORDER BY 1, 3;

-- 8. What is the percentage split of total revenue by category?
SELECT category_name,
       ROUND(SUM((qty * s.price) * (1 - discount * 0.01)) * 100.0 /
             (SELECT SUM((qty * price) * (1 - discount * 0.01)) FROM sales), 2)
           AS rev_category_percentage
FROM sales s
         JOIN product_details pd ON s.prod_id = pd.product_id
GROUP BY category_name;

-- 9. What is the total transaction “penetration” for each product?
-- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
SELECT product_name,
       COUNT(DISTINCT txn_id) * 100.0 / (SELECT COUNT(DISTINCT txn_id) FROM sales)
           AS penetration
FROM sales s
         JOIN product_details pd ON s.prod_id = pd.product_id
WHERE qty >= 1
GROUP BY product_name
ORDER BY 2 DESC;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH base AS (SELECT s.txn_id, s.prod_id, product_name
              FROM sales s
                       JOIN product_details pd ON s.prod_id = pd.product_id)
SELECT a.product_name, b.product_name, c.product_name, COUNT(*) AS combination_count
FROM base a
         INNER JOIN base b
                    ON a.txn_id = b.txn_id
         INNER JOIN base c
                    ON b.txn_id = c.txn_id
WHERE a.prod_id < b.prod_id
  AND b.prod_id < c.prod_id
GROUP BY a.product_name, b.product_name, c.product_name
ORDER BY 4 DESC
LIMIT 1;