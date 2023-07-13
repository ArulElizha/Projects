/* --------------------
   Case Study - 01: Danny's Dinner Questions
   --------------------*/
set search_path = dannys_diner;
  
select * from sales;
select * from menu;
select * from members;

-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(m.price) as total_sale from sales s 
inner join menu m on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) as visit_count from sales
group by customer_id
order by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
select customer_id,product_name,order_date from 
(select s.customer_id,s.order_date, m.product_id,m.product_name,
dense_rank() over(partition by customer_id order by order_date) as first_item
from sales s inner join menu m 
on s.product_id = m.product_id) a
where first_item = 1
group by customer_id,product_name,order_date;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select s.product_id,m.product_name,count(s.product_id)
from sales s inner join menu m 
on s.product_id = m.product_id
group by 1,2
order by 3 desc
limit 1;

-- 5. Which item was the most popular for each customer?

with ranking as(select s.customer_id,m.product_name,count(*) as sales_count,
				dense_rank() over(partition by s.customer_id order by count(*) desc)
				from sales s inner join menu m 
				on s.product_id = m.product_id
				group by s.customer_id,m.product_name)
select customer_id,product_name,sales_count
from ranking
where dense_rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?

select customer_id,join_date,order_date,product_name
from (select m.customer_id,m.join_date,s.order_date,e.product_name,
row_number() over(partition by m.join_date order by s.order_date) as new_row
from members m inner join sales s
on m.customer_id = s.customer_id inner join menu e
on s.product_id = e.product_id
where order_date >= join_date) a
where new_row =1;

-- 7. Which item was purchased just before the customer became a member?

select m.customer_id,m.join_date,max(s.order_date) as purchased_before_became_member,e.product_name
from members m inner join sales s
on m.customer_id = s.customer_id inner join menu e
on s.product_id = e.product_id
where order_date < join_date
group by m.customer_id,m.join_date,e.product_name
order by  m.customer_id,purchased_before_became_member desc;

-- 8. What is the total items and amount spent for each member before they became a member?

select m.customer_id,count(e.product_id) as Total_count,sum(e.price) as Total_sum
from members m inner join sales s
on m.customer_id = s.customer_id inner join menu e
on s.product_id = e.product_id
where order_date < join_date
group by m.customer_id
order by m.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier-how many points would 
-------each customer have?

select customer_id,
sum(price * points)
from (select s.customer_id,m.product_name, m.price,
case when m.product_name = 'sushi' then  20
else 10
end as points
from menu m inner join sales s
on m.product_id = s.product_id ) a
group by customer_id
order by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points 
-------on all items, not just sushi - how many points do customer A and B have at the end of January?

select customer_id,sum(price * points) total_points_upto_end_of_Jan from 
(select s.customer_id,s.order_date,m.join_date,e.product_name,e.price,
case 
	when s.order_date between m.join_date and m.join_date+6 then 20
	when s.order_date < m.join_date and e.product_name = 'sushi' then 20
	when s.order_date > m.join_date+6 and e.product_name = 'sushi' then 20
	else 10
end as points
from sales s inner join members m
on s.customer_id = m.customer_id
inner join menu e 
on s.product_id = e.product_id) a
where order_date <= '2021-01-31'
group by customer_id
order by customer_id;

--Bonus Questions: 01

create view danny_dinner_data as
select s.customer_id,s.order_date,e.product_name,e.price,
case
	when s.customer_id = 'A' and s.order_date >= (select join_date from members
												 where customer_id = 'A')
	then 'Y' 
	when s.customer_id = 'B' and s.order_date >= (select join_date from members
												 where customer_id = 'B') 
	then 'Y'
	else 'N'
end as members
from sales s left outer join members m
on s.customer_id = m.customer_id
left outer join menu e 
on s.product_id = e.product_id
order by s.customer_id,s.order_date,e.product_name;

select * from danny_dinner_data;

--Bonus Question: 02

select *,
case
	when members = 'N' then null
	else rank() over(partition by customer_id,members order by order_date)
end as ranking
from danny_dinner_data;