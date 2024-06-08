SET search_path = "pizza_runner";

-- Convert exclusions and extras columns from VARCHAR to TEXT.
ALTER TABLE customer_orders
ALTER COLUMN exclusions TYPE TEXT,
ALTER COLUMN extras TYPE TEXT;

-- Replace NULL values with empty strings in the exclusions and extras columns.
UPDATE customer_orders
SET exclusions = ''
WHERE exclusions IS NULL;

UPDATE customer_orders
SET extras = ''
WHERE extras IS NULL;

-- Remove the units (e.g., "km") from the distance column.
UPDATE runner_orders
SET distance = TRIM(BOTH 'km' FROM distance)
WHERE distance IS NOT NULL AND distance LIKE '%km';

-- Convert any non-numeric values to NULL to avoid conversion errors.
UPDATE runner_orders
SET distance = NULL
WHERE distance IS NOT NULL AND NOT distance ~ '^[0-9]+(\.[0-9]+)?$';

-- Convert `pickup_time` to TIMESTAMP, `distance` to numeric, and `duration` to interval
ALTER TABLE runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP USING NULLIF(pickup_time, 'null')::TIMESTAMP,
ALTER COLUMN distance TYPE NUMERIC USING NULLIF(distance, 'null')::NUMERIC,
ALTER COLUMN duration TYPE INTERVAL USING NULLIF(duration, 'null')::INTERVAL;

-- Replace `NULL` values in `cancellation` column with an empty string
UPDATE runner_orders
SET cancellation = ''
WHERE cancellation IS NULL;
