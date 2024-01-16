/* --------------------
   CASE Study - 01: Danny's Dinner QuestiONs
   --------------------*/
SET search_path = dannys_diner;
  
SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id,
	SUM(m.price) AS total_sale 
FROM sales s INNER JOIN menu m 
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id,
	COUNT(DISTINCT order_date) AS visit_COUNT 
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT 
	customer_id,
	product_name,
	order_date 
FROM 
	(SELECT 
		s.customer_id,
		s.order_date, 
		m.product_id,
		m.product_name,
		DENSE_RANK() 
		OVER(PARTITION BY customer_id ORDER BY order_date) AS first_item
	 FROM sales s INNER JOIN menu m 
	 ON s.product_id = m.product_id) a
WHERE first_item = 1
GROUP BY customer_id,product_name,order_date;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	s.product_id,
	m.product_name,
	COUNT(s.product_id) AS no_of_orders
FROM sales s INNER JOIN menu m 
ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY no_of_orders DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH ranking AS(SELECT 
					s.customer_id,
					m.product_name,
					COUNT(*) AS sales_COUNT,
					DENSE_RANK() 
					OVER(PARTITION BY s.customer_id ORDER BY COUNT(*) DESC)
				FROM sales s INNER JOIN menu m 
				ON s.product_id = m.product_id
				GROUP BY s.customer_id,m.product_name)
SELECT 
	customer_id,
	product_name,
	sales_COUNT
FROM ranking
WHERE DENSE_RANK = 1;

-- 6. Which item was purchased first by the customer after they became a member?

SELECT 
	customer_id,
	join_date,
	order_date,
	product_name
FROM 
	(SELECT 
		m.customer_id,
		m.join_date,
		s.order_date,
		e.product_name,
		ROW_NUMBER() 
		OVER(PARTITION BY m.join_date ORDER BY s.order_date) AS new_row
	FROM members m INNER JOIN sales s
	ON m.customer_id = s.customer_id INNER JOIN menu e
	ON s.product_id = e.product_id
	WHERE order_date >= join_date) a
WHERE new_row = 1;

-- 7. Which item was purchased just before the customer became a member?

SELECT 
	m.customer_id,
	m.join_date,
	MAX(s.order_date) AS purchased_before_became_member,
	e.product_name
FROM members m INNER JOIN sales s
ON m.customer_id = s.customer_id INNER JOIN menu e
ON s.product_id = e.product_id
WHERE order_date < join_date
GROUP BY m.customer_id,m.join_date,e.product_name
ORDER BY  m.customer_id,purchased_before_became_member DESC
LIMIT 3;

-- 8. What is the total items AND amount spent for each member before they became a member?

SELECT 
	m.customer_id,
	COUNT(e.product_id) AS Total_COUNT,
	SUM(e.price) AS Total_SUM
FROM members m INNER JOIN sales s
ON m.customer_id = s.customer_id INNER JOIN menu e
ON s.product_id = e.product_id
WHERE order_date < join_date
GROUP BY m.customer_id
ORDER BY m.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier-how many points would 
-------each customer have?

SELECT 
	customer_id,
	SUM(price * points) AS total_points 
FROM 
	(SELECT 
		s.customer_id,
		m.product_name, 
		m.price,
		CASE WHEN m.product_name = 'sushi' THEN  20
		ELSE 10
		END AS points
	FROM menu m INNER JOIN sales s
	ON m.product_id = s.product_id ) a
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points 
---on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT 
	customer_id,
	SUM(price * points) total_points_upto_END_of_Jan
FROM 
	(SELECT 
		s.customer_id,
		s.order_date,
		m.join_date,
		e.product_name,
		e.price,
		CASE 
			WHEN s.order_date between m.join_date AND m.join_date+6 THEN 20
			WHEN s.order_date < m.join_date AND e.product_name = 'sushi' THEN 20
			WHEN s.order_date > m.join_date+6 AND e.product_name = 'sushi' THEN 20
			ELSE 10
		END AS points
	FROM sales s INNER JOIN members m
	ON s.customer_id = m.customer_id
	INNER JOIN menu e 
	ON s.product_id = e.product_id) a
WHERE order_date <= '2021-01-31'
GROUP BY customer_id
ORDER BY customer_id;

--Bonus Questions: Join all the things

CREATE VIEW danny_dinner_data AS
SELECT 
	s.customer_id,
	s.order_date,
	e.product_name,
	e.price,
	CASE
		WHEN s.customer_id = 'A' AND s.order_date >= (SELECT join_date FROM members
													 WHERE customer_id = 'A')
		THEN 'Y' 
		WHEN s.customer_id = 'B' AND s.order_date >= (SELECT join_date FROM members
													 WHERE customer_id = 'B') 
		THEN 'Y'
		ELSE 'N'
	END AS members
FROM sales s LEFT OUTER JOIN members m
ON s.customer_id = m.customer_id
LEFT OUTER JOIN menu e 
ON s.product_id = e.product_id
ORDER BY s.customer_id,s.order_date,e.product_name;

SELECT * FROM danny_dinner_data;

--BONus Question: Rank all the things

SELECT *,
	CASE
		WHEN members = 'N' THEN null
		ELSE RANK() OVER (PARTITION BY customer_id,members ORDER BY order_date)
	END AS RANKing
FROM danny_dinner_data;