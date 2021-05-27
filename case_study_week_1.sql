--schema start
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id") 
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
--schema end




/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
customer_id,
SUM(price)
FROM sales
join menu
on sales.product_id=menu.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT
 customer_id, 
 COUNT(DISTINCT order_date) AS "visited_days"
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH sale_order AS(
  SELECT
  RANK() OVER( 
    PARTITION BY customer_id 
    ORDER BY order_date
  ) AS order_rank,
  customer_id,
  product_name
  FROM sales
  JOIN menu
   ON sales.product_id=menu.product_id
  )
  SELECT DISTINCT 
    customer_id,
    product_name
  FROM sale_order
  WHERE order_rank=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
  menu.product_name,
  COUNT(*) AS total_purchases
FROM sales
INNER JOIN menu
  ON menu.product_id=sales.product_id
  GROUP BY menu.product_name
ORDER BY total_purchases DESC
LIMIT 1
;

-- 5. Which item was the most popular for each customer?

WITH customer_pop AS(
  SELECT
    RANK()OVER(
    PARTITION BY customer_id
    ORDER BY COUNT(*)
    )AS item_rank,
    sales.customer_id,
    menu.product_name,
    COUNT(*)AS quantity
  FROM sales
  JOIN menu
  ON menu.product_id=sales.product_id
  GROUP BY customer_id,product_name
  )
SELECT 
  customer_id,
  product_name,
  quantity
FROM customer_pop
WHERE item_rank=1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH first_memb_sale AS(
  SELECT
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  RANK()OVER(
    PARTITION BY sales.customer_id
    ORDER BY order_date
    )AS order_rank
  FROM sales
  JOIN members
  ON sales.customer_id=members.customer_id
  JOIN menu
  ON sales.product_id=menu.product_id
  WHERE sales.order_date>=members.join_date::DATE
)

SELECT 
customer_id,
order_date,
product_name
FROM first_memb_sale
WHERE order_rank=1
GROUP BY customer_id,order_date,product_name;

-- 7. Which item was purchased just before the customer became a member?

WITH before_memb_sale AS(
  SELECT 
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  RANK() OVER(
    PARTITION BY sales.customer_id
    ORDER BY order_date DESC
  )AS order_rank
  FROM sales
  JOIN members
  ON sales.customer_id=members.customer_id
  JOIN menu
  on sales.product_id=menu.product_id
  WHERE sales.order_date<members.join_date::DATE
)

SELECT
customer_id,
order_date,
product_name
FROM before_memb_sale 
WHERE order_rank=1
GROUP BY customer_id,order_date,product_name;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
sales.customer_id,
COUNT(DISTINCT sales.product_id) AS unique_items,
SUM(menu.price) AS total_spent
FROM sales
JOIN menu
ON sales.product_id=menu.product_id
JOIN members
ON sales.customer_id=members.customer_id
WHERE sales.order_date<members.join_date::DATE
GROUP BY sales.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- 11. How total purchases has the customer done?

SELECT
  customer_id,
  COUNT(*) AS total_purchases
FROM sales
INNER JOIN menu
  ON menu.product_id=sales.product_id
  GROUP BY customer_id
ORDER BY total_purchases DESC;

