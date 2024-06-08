/* --------------------
   Case Study Questions
   --------------------*/
SET search_path = "pizza_runner";

-- 1. How many pizzas were ordered?
SELECT COUNT(*) as total_pizzas_ordered
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS successful_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT pn.pizza_name, COUNT(co.order_id) AS delivered_pizzas
FROM customer_orders co
         JOIN runner_orders ro ON co.order_id = ro.order_id
         JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL
GROUP BY pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT co.customer_id, pn.pizza_name, COUNT(co.order_id) AS pizzas_ordered
FROM customer_orders co
         JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, pn.pizza_name
ORDER BY  customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT MAX(total_pizzas) AS max_pizzas_delivered
FROM
    (SELECT co.order_id, COUNT(co.pizza_id) AS total_pizzas
    FROM customer_orders co
        JOIN runner_orders ro ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL
    GROUP BY co.order_id) as subquery;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT co.customer_id,
       COUNT(CASE WHEN (co.exclusions IS NOT NULL)
           OR (co.extras IS NOT NULL) THEN 1 END) AS with_changes,
       COUNT(CASE WHEN (co.exclusions IS NULL)
           AND (co.extras IS NULL) THEN 1 END) AS without_changes
FROM customer_orders co
         JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*)
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE (co.exclusions IS NOT NULL )
  AND (co.extras IS NOT NULL)
  AND (ro.cancellation IS NULL);

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM co.order_time) as hour_of_day, COUNT(*) as total_pizzas_ordered
FROM customer_orders co
GROUP BY EXTRACT(HOUR FROM co.order_time)
ORDER BY hour_of_day;

-- 10. What was the volume of orders for each day of the week?
SELECT TO_CHAR(co.order_time, 'Day') AS day_of_week, COUNT(*) AS total_orders
FROM customer_orders co
GROUP BY TO_CHAR(co.order_time, 'Day')
ORDER BY TO_CHAR(co.order_time, 'Day');
-- Alternative for order by day of the week
SELECT
    CASE EXTRACT(DOW FROM order_time)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        END AS day_of_week,
    COUNT(*) AS total_orders
FROM customer_orders
GROUP BY EXTRACT(DOW FROM order_time)
ORDER BY EXTRACT(DOW FROM order_time);