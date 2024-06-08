SET search_path = "pizza_runner";

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
    DATE_TRUNC('week', registration_date) AS week_start,
    COUNT(runner_id) AS runners_signed_up
FROM runners
GROUP BY week_start
ORDER BY week_start;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT ro.runner_id, AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60) AS avg_pickup_time_minutes
FROM runner_orders ro
         JOIN customer_orders co ON ro.order_id = co.order_id
WHERE ro.pickup_time IS NOT NULL
GROUP BY ro.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT
    co.order_id,
    COUNT(co.pizza_id) AS num_pizzas,
    EXTRACT(EPOCH FROM (ro.pickup_time - co.order_time)) / 60 AS preparation_time_minutes
FROM customer_orders co
         JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.pickup_time IS NOT NULL
GROUP BY co.order_id, ro.pickup_time, co.order_time
ORDER BY co.order_id;


-- 4. What was the average distance travelled for each customer?
SELECT co.customer_id, AVG(ro.distance) AS avg_distance_km
FROM runner_orders ro
         JOIN customer_orders co ON ro.order_id = co.order_id
WHERE ro.distance IS NOT NULL
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
    (MAX(EXTRACT(EPOCH FROM ro.duration) / 60) - MIN(EXTRACT(EPOCH FROM ro.duration) / 60)) AS delivery_time_difference_minutes
FROM runner_orders ro
WHERE ro.duration IS NOT NULL;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
    ro.runner_id,
    AVG(ro.distance / (EXTRACT(EPOCH FROM ro.duration) / 3600)) AS avg_speed_kmh
FROM runner_orders ro
WHERE ro.distance IS NOT NULL AND ro.duration IS NOT NULL
GROUP BY ro.runner_id;

-- 7. What is the successful delivery percentage for each runner?
SELECT
    ro.runner_id,
    COUNT(CASE WHEN ro.cancellation IS NULL THEN 1 END) * 100.0 / COUNT(*) AS successful_delivery_percentage
FROM runner_orders ro
GROUP BY ro.runner_id;
