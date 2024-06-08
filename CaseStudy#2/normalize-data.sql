SET search_path = "pizza_runner";

-- Replace NULL values with empty strings in the exclusions and extras columns.
UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions = '' OR exclusions = 'null';

UPDATE customer_orders
SET extras = NULL
WHERE extras = '' OR extras = 'null';

-- Add new columns
ALTER TABLE customer_orders
    ADD COLUMN new_exclusions INTEGER[],
    ADD COLUMN new_extras INTEGER[];

-- Update new columns with converted values
UPDATE customer_orders
SET
    new_exclusions = STRING_TO_ARRAY(exclusions, ', ')::INTEGER[],
    new_extras = STRING_TO_ARRAY(extras, ', ')::INTEGER[];

-- Drop existing columns
ALTER TABLE customer_orders
    DROP COLUMN exclusions,
    DROP COLUMN extras;

-- Rename new columns to match original column names
ALTER TABLE customer_orders
RENAME COLUMN new_exclusions TO exclusions;
ALTER TABLE customer_orders
RENAME COLUMN new_extras TO extras;

-- Add new columns
ALTER TABLE pizza_recipes
ADD COLUMN new_toppings INTEGER[];

-- Update new columns with converted values
UPDATE pizza_recipes
SET
    new_toppings = STRING_TO_ARRAY(toppings, ', ')::INTEGER[]

-- Drop existing columns
ALTER TABLE pizza_recipes
    DROP COLUMN toppings;

-- Rename new columns to match original column names
ALTER TABLE pizza_recipes
RENAME COLUMN new_toppings TO toppings;

-- Remove the units (e.g., "km") from the distance column.
UPDATE runner_orders
SET distance = TRIM(BOTH 'km' FROM distance)
WHERE distance IS NOT NULL AND distance LIKE '%km';

-- Convert any non-numeric values to NULL to avoid conversion errors.
UPDATE runner_orders
SET distance = NULL
WHERE distance IS NOT NULL AND NOT distance ~ '^[0-9]+(\.[0-9]+)?$';

-- Convert `pickup_time` to TIMESTAMP, `distance` to numeric, and `duration` to interval
UPDATE runner_orders
SET duration = CAST(SUBSTRING(duration FROM '[0-9]+') || ' minutes' AS INTERVAL);

ALTER TABLE runner_orders
    ALTER COLUMN pickup_time TYPE TIMESTAMP USING NULLIF(pickup_time, 'null')::TIMESTAMP,
    ALTER COLUMN distance TYPE NUMERIC USING NULLIF(distance, 'null')::NUMERIC,
    ALTER COLUMN duration TYPE INTERVAL USING NULLIF(duration, 'null')::INTERVAL;

ALTER TABLE runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP USING NULLIF(pickup_time, 'null')::TIMESTAMP,
ALTER COLUMN distance TYPE NUMERIC USING NULLIF(distance, 'null')::NUMERIC,
ALTER COLUMN duration TYPE INTERVAL USING NULLIF(duration, 'null')::INTERVAL;

-- Replace `NULL` values in `cancellation` column with an empty string
UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = '' OR cancellation = 'null';
