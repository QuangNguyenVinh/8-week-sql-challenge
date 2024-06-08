SET search_path = data_bank;

-- 1. What is the unique count and total amount for each transaction type?
SELECT ct.txn_type, COUNT(*) as unique_count, SUM(ct.txn_amount) as total_amount
FROM customer_transactions ct
GROUP BY ct.txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH deposit_summary AS
         (
             SELECT customer_id,
                    txn_type,
                    COUNT(*) AS deposit_count,
                    SUM(txn_amount) AS deposit_amount
             FROM customer_transactions
             GROUP BY customer_id, txn_type

         )
SELECT txn_type,
       AVG(deposit_count) AS avg_deposit_count,
       AVG(deposit_amount) AS avg_deposit_amount
FROM deposit_summary
WHERE txn_type = 'deposit'
GROUP BY txn_type;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH customer_activity AS
         (
             SELECT customer_id,
                    DATE_PART('Month', txn_date) AS month_id,
                    TO_CHAR(txn_date, 'Month') AS month_name,
                    COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
                    COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
                    COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
             FROM customer_transactions
             GROUP BY customer_id, DATE_PART('Month', txn_date), TO_CHAR(txn_date, 'Month')
         )

SELECT month_id,
       month_name,
       COUNT(DISTINCT customer_id) AS active_customer_count
FROM customer_activity
WHERE deposit_count > 1
  AND (purchase_count > 0 OR withdrawal_count > 0)
GROUP BY month_id, month_name
ORDER BY active_customer_count DESC;

-- 4. What is the closing balance for each customer at the end of the month?
WITH cte AS (
    SELECT customer_id,
           DATE_TRUNC('month', txn_date) AS month_start,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END) AS total_amount
    FROM customer_transactions
    GROUP BY customer_id, DATE_TRUNC('month', txn_date)
)

SELECT cte.customer_id,
       EXTRACT(MONTH FROM cte.month_start) AS month,
       TO_CHAR(cte.month_start, 'Month') AS month_name,
       SUM(cte.total_amount) OVER (PARTITION BY cte.customer_id ORDER BY cte.month_start) AS closing_balance
FROM cte;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH monthly_transactions AS (
    SELECT customer_id,
           (DATE_TRUNC('month', txn_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE AS end_date,
           SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN - txn_amount ELSE txn_amount END) AS transactions
    FROM customer_transactions
    GROUP BY customer_id, (DATE_TRUNC('month', txn_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE
), closing_balances AS (
     SELECT customer_id,
            end_date,
            COALESCE(SUM(transactions) OVER(PARTITION BY customer_id ORDER BY end_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS closing_balance
     FROM monthly_transactions
 ), pct_increase AS (
     SELECT customer_id,
            end_date,
            closing_balance,
            LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY end_date) AS prev_closing_balance,
            100 * (closing_balance - LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY end_date)) / NULLIF(LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY end_date), 0) AS pct_increase
     FROM closing_balances
 )
SELECT CAST(100.0 * COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) AS FLOAT) AS pct_customers
FROM pct_increase
WHERE pct_increase > 5;
