-- 1. What was the total quantity sold for all products?
SELECT SUM(qty) AS total_quantity_sold
FROM sales s
         JOIN product_details p
              ON s.prod_id = p.product_id;

-- 2. What is the total generated revenue for all products before discounts?
SELECT SUM((qty * s.price) * (1 - discount * 0.01)) AS total_revenues
FROM sales s
         JOIN product_details pd
              ON s.prod_id = pd.product_id;

-- 3. What was the total discount amount for all products?
SELECT ROUND(SUM((discount * (qty * s.price) / 100.0)), 2) AS total_discounts
FROM sales s
         JOIN product_details pd
              ON s.prod_id = pd.product_id