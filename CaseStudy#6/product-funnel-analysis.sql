-- Using a single SQL query — create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?

DROP TABLE IF EXISTS products;
CREATE TABLE products
(
    page_name             varchar,
    page_views            int,
    cart_adds             int,
    cart_add_not_purchase int,
    cart_add_purchase     int
);

WITH x AS (SELECT e.visit_id,
                  page_name,
                  SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END)   AS view_count,
                  SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds
           FROM events e
                    JOIN page_hierarchy p
                         ON e.page_id = p.page_id
                    JOIN event_identifier ei
                         ON e.event_type = ei.event_type
           WHERE product_id IS NOT NULL
           GROUP BY e.visit_id, page_name),
     y AS (SELECT DISTINCT(visit_id) AS purchase_id
           FROM events e
                    JOIN event_identifier ei
                         ON e.event_type = ei.event_type
           WHERE event_name = 'Purchase'),
     z AS (SELECT *,
                  (CASE WHEN purchase_id IS NOT NULL THEN 1 ELSE 0 END) AS purchase
           FROM x
                    LEFT JOIN y
                              ON visit_id = purchase_id),
     t AS (SELECT page_name,
                  SUM(view_count) AS page_views,
                  SUM(cart_adds)  AS cart_adds,
                  SUM(CASE
                          WHEN cart_adds = 1 AND purchase = 0 THEN 1
                          ELSE 0
                      END)        AS cart_add_not_purchase,
                  SUM(CASE
                          WHEN cart_adds = 1 AND purchase = 1 THEN 1
                          ELSE 0
                      END)        AS cart_add_purchase
           FROM z
           GROUP BY page_name)

INSERT
INTO products
(page_name, page_views, cart_adds, cart_add_not_purchase, cart_add_purchase)
SELECT page_name, page_views, cart_adds, cart_add_not_purchase, cart_add_purchase
FROM t;
-- Additionally, create another table which further aggregates the data for the above points
-- but this time for each product category instead of individual products.
DROP TABLE IF EXISTS product_category;
CREATE TABLE product_category
(
    product_category      varchar,
    page_views            int,
    cart_adds             int,
    cart_add_not_purchase int,
    cart_add_purchase     int
);
WITH x AS (SELECT e.visit_id,
                  product_category,
                  page_name,
                  SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END)   AS view_count,
                  SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds
           FROM events e
                    JOIN page_hierarchy p
                         ON e.page_id = p.page_id
                    JOIN event_identifier ei
                         ON e.event_type = ei.event_type
           WHERE product_id IS NOT NULL
           GROUP BY e.visit_id, product_category, page_name),
     y AS (SELECT DISTINCT(visit_id) AS purchase_id
           FROM events e
                    JOIN event_identifier ei
                         ON e.event_type = ei.event_type
           WHERE event_name = 'Purchase'),
     z AS (SELECT *,
                  (CASE WHEN purchase_id IS NOT NULL THEN 1 ELSE 0 END) AS purchase
           FROM x
                    LEFT JOIN y
                              ON visit_id = purchase_id),
     t AS (SELECT product_category,
                  SUM(view_count) AS page_views,
                  SUM(cart_adds)  AS cart_adds,
                  SUM(CASE
                          WHEN cart_adds = 1 AND purchase = 0 THEN 1
                          ELSE 0
                      END)        AS cart_add_not_purchase,
                  SUM(CASE
                          WHEN cart_adds = 1 AND purchase = 1 THEN 1
                          ELSE 0
                      END)        AS cart_add_purchase
           FROM z
           GROUP BY product_category)

INSERT
INTO product_category
(product_category, page_views, cart_adds, cart_add_not_purchase, cart_add_purchase)
SELECT product_category, page_views, cart_adds, cart_add_not_purchase, cart_add_purchase
FROM t;

-- Which product had the most views, cart adds and purchases?
SELECT page_name AS most_viewed
FROM products
ORDER BY page_views DESC
LIMIT 1;

SELECT page_name AS card_add
FROM products
ORDER BY cart_adds DESC
LIMIT 1;

SELECT page_name AS purchase
FROM products
ORDER BY cart_add_purchase DESC
LIMIT 1;

-- Which product was most likely to be abandoned?
SELECT page_name AS abandoned
FROM products
ORDER BY cart_add_not_purchase DESC
LIMIT 1;

-- Which product had the highest view to purchase percentage?
SELECT page_name AS product,
       ROUND(cart_add_purchase * 100.0 / page_views, 2)
                 AS view_purchase_percentage
FROM products
ORDER BY 2 DESC
LIMIT 1;

-- What is the average conversion rate from view to cart add?
SELECT ROUND(AVG(cart_adds * 100.0 / page_views), 2) AS avg_rate_view_to_cart
FROM products;

-- What is the average conversion rate from cart add to purchase?
SELECT ROUND(AVG(cart_add_purchase * 100.0 / cart_adds), 2)
           AS avg_rate_cart_to_purchase
FROM products;