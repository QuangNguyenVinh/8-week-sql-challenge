-- Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
-- Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.
-- He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).
SELECT category_name,
       segment_name,
       s.prod_id,
       p.product_name,
       SUM(qty)                                                                     AS sold,
       SUM((qty * s.price) * (1 - discount * 0.01))                                 AS total_revenues,
       ROUND(SUM((discount * (qty * s.price) / 100.0)), 2)                          AS total_discount,
       ROUND(SUM((qty * s.price) * (1 - discount * 0.01)) * 100.0 /
             (SELECT SUM((qty * price) * (1 - discount * 0.01)) FROM sales), 2)     AS revenue_percentage,
       COUNT(DISTINCT txn_id) * 100.0 / (SELECT COUNT(DISTINCT txn_id) FROM sales)  AS penetration,
       SUM(CASE WHEN member = 't' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)             AS member_transaction,
       SUM(CASE WHEN member = 'f' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)             AS non_member_transaction,
       AVG(CASE WHEN member = 't' THEN (qty * s.price) * (1 - discount * 0.01) END) AS avg_revenue_member,
       AVG(CASE WHEN member = 'f' THEN (qty * s.price) * (1 - discount * 0.01) END) AS avg_revenue_non_member
FROM sales s
         JOIN product_details p
              ON s.prod_id = p.product_id
WHERE TO_CHAR(s.start_txn_time, 'Month') = 'January'
GROUP BY category_name, segment_name, s.prod_id, p.product_name
ORDER BY 1, 2, 6 DESC;