SET search_path = "pizza_runner";

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
WITH cte AS (SELECT pizza_id,
                    pizza_name,
                    CASE WHEN pizza_name = 'Meatlovers' THEN 12
                         ELSE 10 END AS pizza_cost
             FROM pizza_names)

SELECT SUM(pizza_cost) as total_revenue
FROM customer_orders co
         JOIN runner_orders ro ON co.order_id = ro.order_id
         JOIN cte ON co.pizza_id = cte.pizza_id
WHERE ro.cancellation is NULL;

-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
WITH pizza_cte AS
         (SELECT
              (CASE WHEN pizza_id = 1 THEN 12
                    WHEN pizza_id = 2 THEN 10
                  END) AS pizza_cost,
              co.exclusions,
              co.extras
          FROM runner_orders ro
                   JOIN customer_orders co ON co.order_id = ro.order_id
          WHERE ro.cancellation IS  NULL
         )
SELECT
    SUM(CASE WHEN extras IS NULL THEN pizza_cost
             WHEN array_length(extras, 1) = 1 THEN pizza_cost + 1
             ELSE pizza_cost + 2
        END ) AS total_earn
FROM pizza_cte;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings
(order_id INTEGER,
 rating INTEGER);
INSERT INTO ratings
(order_id ,rating)
VALUES
    (1,3),
    (2,4),
    (3,1),
    (4,5),
    (5,2),
    (6,2),
    (7,1),
    (8,5),
    (9,4),
    (10,4);
-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
SELECT customer_id ,
       co.order_id,
       runner_id,
       rating,
       order_time,
       pickup_time,
       EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60 as time_order_pickup,
       ro.duration,
       ROUND(AVG(ro.distance / (EXTRACT(EPOCH FROM ro.duration) / 3600)),2) AS avg_speed_kmh,
       COUNT(pizza_id) AS pizza_count
FROM customer_orders co
         LEFT JOIN runner_orders ro ON co.order_id = ro.order_id
         LEFT JOIN ratings r2 ON co.order_id = r2.order_id
WHERE ro.cancellation is NULL
GROUP BY customer_id , co.order_id, runner_id, rating, order_time, pickup_time, EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60 , ro.duration
ORDER BY co.customer_id;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH cte AS (SELECT co.order_id,
                    SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 12
                             ELSE 10 END) AS pizza_cost
             FROM pizza_names pn
                      JOIN customer_orders co ON pn.pizza_id = co.pizza_id
             GROUP BY co.order_id)

SELECT SUM(pizza_cost) AS revenue,
       SUM(distance) * 0.3 as total_cost,
       SUM(pizza_cost) - SUM(distance) * 0.3 as profit
FROM runner_orders ro
         JOIN cte ON ro.order_id = cte.order_id
WHERE ro.cancellation is NULL