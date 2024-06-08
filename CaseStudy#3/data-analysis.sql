SET search_path = foodie_fi;

-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT DATE_TRUNC('month', start_date) AS start_month, COUNT(*) AS trial_customers
FROM subscriptions
WHERE plan_id = 0
GROUP BY start_month
ORDER BY start_month;
-- Alternative
SELECT DATE_PART('month', start_date) as month ,
       DATE_PART('year', start_date) as year,
       COUNT(customer_id) as number_of_trial
FROM subscriptions s
         LEFT JOIN plans p ON s.plan_id =p.plan_id
WHERE plan_name = 'trial'
GROUP BY DATE_PART('month', start_date),
         DATE_PART('year', start_date);

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT p.plan_name, s.start_date, COUNT(*) as count
FROM plans p
JOIN subscriptions s ON p.plan_id = s.plan_id
WHERE s.start_date > '2020-01-01' -- OR DATE_PART('year', s.start_date) > 2020
GROUP BY p.plan_name, s.start_date;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
    COUNT(DISTINCT customer_id) AS churned_customers,
    ROUND(COUNT(DISTINCT customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS churned_percentage
FROM subscriptions
WHERE plan_id = 4;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte AS(SELECT *,
                   LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) AS next_plan
            FROM subscriptions
)
SELECT plan_name,
       COUNT(next_plan) as number_churn,
       COUNT(next_plan) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS perc_straight_churn
FROM CTE c
         LEFT JOIN plans p ON c.next_plan = p.plan_id
WHERE next_plan = 4 and c.plan_id = 0
GROUP BY plan_name;

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH cte AS(SELECT *,
                   LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
            FROM subscriptions
)
SELECT plan_name, COUNT(*) as num_plan, COUNT(next_plan) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS perc_next_plan
FROM cte c
LEFT JOIN plans p ON c.next_plan = p.plan_id
WHERE c.plan_id = 0 AND next_plan IS NOT NULL
GROUP BY plan_name, next_plan;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH cte AS(SELECT *,
                   LEAD(start_date,1) OVER( PARTITION BY customer_id ORDER BY plan_id) AS next_date
            FROM subscriptions
            WHERE start_date <= '2020-12-31')

SELECT c.plan_id, plan_name,
       COUNT(c.plan_id)  AS customer_count,
       COUNT(c.plan_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS Percentage_customer
FROM cte c LEFT JOIN plans p ON c.plan_id = p.plan_id
WHERE next_date IS NULL or next_date > '2020-12-31'
GROUP BY C.plan_id,plan_name
ORDER BY plan_id;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT plan_name,
       COUNT(s.plan_id) AS number_annual_plan
FROM subscriptions s
         INNER JOIN plans p ON s.plan_id = p.plan_id
WHERE plan_name = 'pro annual' AND start_date <= '2020-12-31'
GROUP BY plan_name;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH start_cte AS (SELECT customer_id,
                          start_date
                   FROM subscriptions s
                            JOIN plans p ON s.plan_id = p.plan_id
                   WHERE plan_name = 'trial' ),

     annual_cte AS (SELECT customer_id,
                           start_date as start_annual
                    FROM subscriptions s
                            JOIN plans p ON s.plan_id = p.plan_id
                    WHERE plan_name = 'pro annual' )

SELECT AVG(ABS(start_annual - start_date)) as average_day
FROM annual_cte c2
         LEFT JOIN start_cte c1 ON c2.customer_id = c1.customer_id;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH START_CTE AS (
    SELECT customer_id,
           start_date
    FROM subscriptions s
             INNER JOIN plans p ON s.plan_id = p.plan_id
    WHERE plan_name = 'trial' ),

     ANNUAL_CTE AS ( SELECT customer_id,
                            start_date AS start_annual
                     FROM subscriptions s
                              INNER JOIN plans p ON s.plan_id = p.plan_id
                     WHERE plan_name = 'pro annual' ),

     DIFF_DAY_CTE AS ( SELECT ABS(start_annual - start_date) AS diff_day
                        FROM ANNUAL_CTE c2
                        LEFT JOIN START_CTE c1 ON c2.customer_id = c1.customer_id),

     GROUP_DAY_CTE AS ( SELECT *, FLOOR(diff_day / 30) AS group_day
                        FROM DIFF_DAY_CTE)

SELECT group_day,
    CONCAT((group_day * 30) + 1 , '-' ,(group_day + 1) * 30, ' days') AS days,
    COUNT(group_day) AS number_days
FROM GROUP_DAY_CTE
GROUP BY group_day;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH cte AS (SELECT *,
                   LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) AS next_plan
            FROM subscriptions
            WHERE start_date <= '2020-12-31')

SELECT COUNT(*) as num_downgrade
FROM cte
WHERE next_plan = 1 and plan_id = 2;