SET search_path = "pizza_runner";

-- 1. What are the standard ingredients for each pizza?
SELECT
    pn.pizza_name,
    STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) AS topping_names
FROM
    pizza_names pn
        JOIN
    pizza_recipes pr ON pn.pizza_id = pr.pizza_id
        JOIN
    (SELECT pr.pizza_id, UNNEST(pr.toppings) AS topping_id
     FROM pizza_recipes pr) AS pr_toppings ON pr.pizza_id = pr_toppings.pizza_id
        JOIN
    pizza_toppings pt ON pt.topping_id = pr_toppings.topping_id
GROUP BY
    pn.pizza_name;

-- 2. What was the most commonly added extra?
SELECT pt.topping_name, subquery.count
FROM (SELECT
          UNNEST(extras) AS extra,
          COUNT(*) AS count
      FROM customer_orders co
      WHERE extras IS NOT NULL
      GROUP BY extra
      ORDER BY count DESC
      LIMIT 1) as subquery
         JOIN pizza_toppings pt
              ON pt.topping_id = subquery.extra;

-- 3. What was the most common exclusion?
SELECT pt.topping_name, subquery.count
FROM (SELECT
          UNNEST(exclusions) AS exclusions,
          COUNT(*) AS count
      FROM customer_orders co
      WHERE exclusions IS NOT NULL
      GROUP BY exclusions
      ORDER BY count DESC
      LIMIT 1) as subquery
         JOIN pizza_toppings pt
              ON pt.topping_id = subquery.exclusions;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH exclusions AS (
    SELECT
        co_have_exclusions.order_id,
        STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) AS exclusion_names
    FROM
        (SELECT co.order_id as order_id,
                UNNEST(co.exclusions) AS topping_id
         FROM customer_orders co
         WHERE  co.exclusions IS NOT NULL) AS co_have_exclusions
            JOIN
        pizza_toppings pt ON pt.topping_id = co_have_exclusions.topping_id
    GROUP BY
        co_have_exclusions.order_id
), extras AS (
    SELECT
        co_have_extra.order_id,
        STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) AS extra_names
    FROM
        (SELECT co.order_id as order_id,
                UNNEST(co.extras) AS topping_id
         FROM customer_orders co
         WHERE  co.extras IS NOT NULL) AS co_have_extra
            JOIN
        pizza_toppings pt ON pt.topping_id = co_have_extra.topping_id
    GROUP BY
        co_have_extra.order_id
)
SELECT
    co.order_id,
    pn.pizza_name ||
    COALESCE(' - Exclude ' || ex.exclusion_names, '') ||
    COALESCE(' - Extra ' || exr.extra_names, '') AS order_item
FROM
    customer_orders co
        JOIN
    pizza_names pn ON co.pizza_id = pn.pizza_id
        LEFT JOIN
    exclusions ex ON co.order_id = ex.order_id
        LEFT JOIN
    extras exr ON co.order_id = exr.order_id;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- TBD


-- 6.What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
SELECT
    pt.topping_name,
    COUNT(*) AS total_quantity
FROM
    customer_orders co
        JOIN
    pizza_recipes pr ON co.pizza_id = pr.pizza_id
        JOIN
    pizza_toppings pt ON pt.topping_id = ANY(pr.toppings)
GROUP BY
    pt.topping_name
ORDER BY
    total_quantity DESC;