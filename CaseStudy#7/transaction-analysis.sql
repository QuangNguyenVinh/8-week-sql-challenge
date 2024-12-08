-- 1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS unique_transactions
FROM sales;

-- 2. What is the average unique products purchased in each transaction?
WITH prods AS (SELECT DISTINCT txn_id, COUNT(prod_id) OVER (PARTITION BY txn_id) AS prod
               FROM sales)
SELECT SUM(prod) / COUNT(txn_id) AS avg_unique_prods
FROM prods;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ((qty * price) * (1 - discount * 0.01))) AS percentile_25,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ((qty * price) * (1 - discount * 0.01)))  AS percentile_50,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ((qty * price) * (1 - discount * 0.01))) AS percentile_75
FROM sales;

-- 4. What is the average discount value per transaction?
SELECT ROUND(AVG(discount * qty * price / 100.0), 2) AS avg_discount
FROM sales;

-- 5. What is the percentage split of all transactions for members vs non-members?
SELECT SUM(CASE WHEN member = 't' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS member,
       SUM(CASE WHEN member = 'f' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS non_member
FROM sales;
-- 6. What is the average revenue for member transactions and non-member transactions?
SELECT AVG(CASE WHEN member = 't' THEN (qty * price) * (1 - discount * 0.01) END) AS avg_revenue_member,
       AVG(CASE WHEN member = 'f' THEN (qty * price) * (1 - discount * 0.01) END) AS avg_revenue_non_member
FROM sales;