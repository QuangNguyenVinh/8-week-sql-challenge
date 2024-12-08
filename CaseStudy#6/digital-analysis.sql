-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id)
FROM users;

-- 2. How many cookies does each user have on average?
WITH cookies AS (SELECT user_id, COUNT(DISTINCT cookie_id) AS total_cookies
                 FROM users
                 GROUP BY user_id)
SELECT ROUND(SUM(total_cookies) / COUNT(user_id), 2) AS avg_cookie
FROM cookies;

-- 3. What is the unique number of visits by all users per month?
SELECT TO_CHAR(event_time, 'Month'),
       COUNT(DISTINCT visit_id)
FROM events
GROUP BY TO_CHAR(event_time, 'Month');

-- 4. What is the number of events for each event type?
SELECT DISTINCT e.event_type, ei.event_name, COUNT(*)
FROM events e
         JOIN event_identifier ei
              ON e.event_type = ei.event_type
GROUP BY e.event_type, ei.event_name
ORDER BY 1, 2;

-- 5. What is the percentage of visits which have a purchase event?
SELECT ROUND(COUNT(DISTINCT visit_id) * 100.0 / (SELECT COUNT(DISTINCT visit_id) FROM events), 2)
FROM events e
         JOIN event_identifier ei
              ON e.event_type = ei.event_type
WHERE ei.event_name = 'Purchase';

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH cte AS (SELECT DISTINCT visit_id,
                             SUM(CASE WHEN event_name != 'Purchase' AND page_id = 12 THEN 1 ELSE 0 END) AS checkouts,
                             SUM(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END)                   AS purchases
             FROM events e
                      JOIN event_identifier ei
                           ON e.event_type = ei.event_type
             GROUP BY visit_id)
SELECT SUM(checkouts)                                          AS total_checkouts,
       SUM(purchases)                                          AS total_purchases,
       100 - ROUND(SUM(purchases) * 100.0 / SUM(checkouts), 2) AS percentage
FROM cte;

-- 7. What are the top 3 pages by number of views?
SELECT p.page_name, COUNT(visit_id) AS total_visits
FROM events e
         JOIN page_hierarchy p
              ON e.page_id = p.page_id
GROUP BY p.page_name
ORDER BY 2 DESC
LIMIT 3;

-- 8. What is the number of views and cart adds for each product category?
SELECT product_category,
       SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END)   AS views,
       SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds
FROM events e
         JOIN event_identifier ei
              ON e.event_type = ei.event_type
         JOIN page_hierarchy p
              ON p.page_id = e.page_id
WHERE product_category IS NOT NULL
GROUP BY product_category;

-- 9. What are the top 3 products by purchases?
SELECT p.product_category, COUNT(visit_id) as total_purchases
FROM events e
         JOIN event_identifier ei
              ON e.event_type = ei.event_type
         JOIN page_hierarchy p
              ON p.page_id = e.page_id
WHERE ei.event_name = 'Purchase'
  AND p.product_category IS NOT NULL
GROUP BY p.product_category
ORDER BY COUNT(visit_id) DESC;