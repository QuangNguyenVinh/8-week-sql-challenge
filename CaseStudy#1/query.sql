/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
  s.customer_id, 
  SUM(m.price) AS total_amount_spent
FROM 
  dannys_diner.sales s
JOIN 
  dannys_diner.menu m 
ON s.product_id = m.product_id
GROUP BY 
  s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT 
  customer_id, 
  COUNT(DISTINCT order_date) AS visit_days
FROM 
  dannys_diner.sales
GROUP BY 
  customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH first_purchase AS (
  SELECT 
    customer_id, 
    MIN(order_date) AS first_order_date
  FROM 
    dannys_diner.sales
  GROUP BY 
    customer_id
)
SELECT 
  fp.customer_id, 
  s.product_id, 
  m.product_name
FROM 
  first_purchase fp
JOIN 
  dannys_diner.sales s 
ON fp.customer_id = s.customer_id AND fp.first_order_date = s.order_date
JOIN 
  dannys_diner.menu m 
ON s.product_id = m.product_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
  m.product_name, 
  COUNT(s.product_id) AS purchase_count
FROM 
  dannys_diner.sales s
JOIN 
  dannys_diner.menu m 
ON s.product_id = m.product_id
GROUP BY 
  m.product_name
ORDER BY 
  purchase_count DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?
WITH customer_purchases AS (
  SELECT 
    s.customer_id, 
    s.product_id, 
    m.product_name, 
    COUNT(s.product_id) AS purchase_count
  FROM 
    dannys_diner.sales s
  JOIN 
    dannys_diner.menu m ON s.product_id = m.product_id
  GROUP BY 
    s.customer_id, 
    s.product_id, 
    m.product_name
),
ranked_purchases AS (
  SELECT 
    cp.customer_id, 
    cp.product_name, 
    cp.purchase_count,
    RANK() OVER (PARTITION BY cp.customer_id ORDER BY cp.purchase_count DESC) AS rank
  FROM 
    customer_purchases cp
)
SELECT 
  rp.customer_id, 
  rp.product_name, 
  rp.purchase_count
FROM 
  ranked_purchases rp
WHERE 
  rp.rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH member_purchases AS (
  SELECT 
    s.customer_id, 
    s.order_date, 
    s.product_id, 
    m.join_date
  FROM 
    dannys_diner.sales s
  JOIN 
    dannys_diner.members m 
  ON s.customer_id = m.customer_id
  WHERE 
    s.order_date >= m.join_date
)
SELECT 
  mp.customer_id, 
  mp.product_id, 
  menu.product_name, 
  mp.order_date
FROM 
  member_purchases mp
JOIN 
  dannys_diner.menu 
ON mp.product_id = menu.product_id
WHERE 
  (mp.customer_id, mp.order_date) IN (
    SELECT 
      customer_id, 
      MIN(order_date)
    FROM 
      member_purchases
    GROUP BY 
      customer_id
  );


-- 7. Which item was purchased just before the customer became a member?
WITH pre_member_purchases AS (
  SELECT 
    s.customer_id, 
    s.order_date, 
    s.product_id, 
    m.join_date
  FROM 
    dannys_diner.sales s
  JOIN 
    dannys_diner.members m 
  ON s.customer_id = m.customer_id
  WHERE 
    s.order_date < m.join_date
)
SELECT 
  pmp.customer_id, 
  pmp.product_id, 
  menu.product_name, 
  pmp.order_date
FROM 
  pre_member_purchases pmp
JOIN 
  dannys_diner.menu 
ON pmp.product_id = menu.product_id
WHERE 
  (pmp.customer_id, pmp.order_date) IN (
    SELECT 
      customer_id, 
      MAX(order_date)
    FROM 
      pre_member_purchases
    GROUP BY 
      customer_id
  );


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
  s.customer_id, 
  COUNT(s.product_id) AS total_items, 
  SUM(m.price) AS total_amount_spent
FROM 
  dannys_diner.sales s
JOIN 
  dannys_diner.menu m 
ON s.product_id = m.product_id
JOIN 
  dannys_diner.members mb 
ON s.customer_id = mb.customer_id
WHERE 
  s.order_date < mb.join_date
GROUP BY 
  s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
  s.customer_id, 
  SUM(
    CASE 
      WHEN m.product_name = 'sushi' THEN m.price * 20
      ELSE m.price * 10
    END
  ) AS total_points
FROM 
  dannys_diner.sales s
JOIN 
  dannys_diner.menu m 
ON s.product_id = m.product_id
GROUP BY 
  s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH points_calculation AS (
  SELECT 
    s.customer_id, 
    s.order_date, 
    m.product_name, 
    m.price,
    CASE 
      WHEN m.product_name = 'sushi' THEN 20
      ELSE 10
    END AS base_points,
    CASE 
      WHEN s.order_date BETWEEN mb.join_date AND mb.join_date + INTERVAL '6 days' THEN 2
      ELSE 1
    END AS multiplier
  FROM 
    dannys_diner.sales s
  JOIN 
    dannys_diner.menu m 
  ON s.product_id = m.product_id
  JOIN 
    dannys_diner.members mb 
  ON s.customer_id = mb.customer_id
)
SELECT 
  pc.customer_id, 
  SUM(pc.price * pc.base_points * pc.multiplier) AS total_points
FROM 
  points_calculation pc
WHERE 
  pc.order_date <= '2021-01-31'
GROUP BY 
  pc.customer_id;



