-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
-- Hint: you may want to consider using a recursive CTE to solve this problem!

WITH cat AS (SELECT id AS cat_id, level_text AS category
             FROM product_hierarchy
             WHERE level_name = 'Category'),
     seg AS (SELECT parent_id AS cat_id, id AS seg_id, level_text AS segment
             FROM product_hierarchy
             WHERE level_name = 'Segment'),
     style AS (SELECT parent_id AS seg_id, id AS style_id, level_text AS style
               FROM product_hierarchy
               WHERE level_name = 'Style'),
     prod_final AS (SELECT c.cat_id AS category_id,
                           category AS category_name,
                           s.seg_id AS segment_id,
                           segment  AS segment_name,
                           style_id,
                           style    AS style_name
                    FROM cat c
                             JOIN seg s
                                  ON c.cat_id = s.cat_id
                             JOIN style st ON s.seg_id = st.seg_id)
SELECT product_id,
       price,
       CONCAT(style_name, ' ', segment_name, ' - ', category_name) AS product_name,
       category_id,
       segment_id,
       style_id,
       category_name,
       segment_name,
       style_name
FROM prod_final pf
         JOIN product_prices pp
              ON pf.style_id = pp.id;