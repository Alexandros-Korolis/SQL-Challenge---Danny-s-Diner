-- 1.What is the total amount each customer spent at the restaurant?

select dannys_diner.sales.customer_id, sum(dannys_diner.menu.price)
from dannys_diner.sales
inner join dannys_diner.menu
on dannys_diner.sales.product_id = dannys_diner.menu.product_id
group by dannys_diner.sales.customer_id
order by dannys_diner.sales.customer_id;

-- 2.How many days has each customer visited the restaurant?

select dannys_diner.sales.customer_id, count(distinct dannys_diner.sales.order_date)
from dannys_diner.sales
group by dannys_diner.sales.customer_id;

-- 3.What was the first item from the menu purchased by each customer?

with min_date as (
select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.sales.product_id, 
	row_number()over(partition by dannys_diner.sales.customer_id order by dannys_diner.sales.order_date asc) as r_n
from dannys_diner.sales)

select min_date.customer_id, min_date.order_date,dannys_diner.menu.product_name
from min_date
inner join dannys_diner.menu
on min_date.product_id = dannys_diner.menu.product_id
where r_n = 1;

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?
with total_purch as (
select dannys_diner.sales.product_id,count(dannys_diner.sales.product_id) as n_purch
from dannys_diner.sales
group by dannys_diner.sales.product_id)

select dannys_diner.menu.product_name, total_purch.n_purch
from dannys_diner.menu
inner join total_purch
on dannys_diner.menu.product_id = total_purch.product_id
order by total_purch.n_purch desc
limit 1;

-- 5.Which item was the most popular for each customer?
with count_prod as (
select dannys_diner.sales.customer_id,dannys_diner.sales.product_id, count(dannys_diner.sales.product_id) as c_t
from dannys_diner.sales
group by dannys_diner.sales.customer_id, dannys_diner.sales.product_id
order by dannys_diner.sales.customer_id, count(dannys_diner.sales.product_id) desc),

row_num_count as (
select customer_id,product_id,c_t, row_number() over(partition by customer_id order by c_t desc) as r_n
from count_prod)

select row_num_count.customer_id, dannys_diner.menu.product_name, row_num_count.c_t as total_times_ordered
from row_num_count
inner join dannys_diner.menu
on dannys_diner.menu.product_id = row_num_count.product_id
where r_n = 1;

-- 6.Which item was purchased first by the customer after they became a member?
with a_join_date as (
select *
from dannys_diner.members
where dannys_diner.members.customer_id = 'A'),

b_join_date as (
select *
from dannys_diner.members
where dannys_diner.members.customer_id = 'B'),

row_ct as (
select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.sales.product_id,
	row_number() over (partition by customer_id) as r_n
from dannys_diner.sales
where (dannys_diner.sales.customer_id in (select customer_id from a_join_date)
	  and dannys_diner.sales.order_date >= (select join_date from a_join_date))
or (dannys_diner.sales.customer_id in (select customer_id from b_join_date)
	  and dannys_diner.sales.order_date >= (select join_date from b_join_date)))

select customer_id, order_date, dannys_diner.menu.product_name
from row_ct
inner join dannys_diner.menu
on dannys_diner.menu.product_id = row_ct.product_id
where r_n = 1;

-- 7.Which item was purchased just before the customer became a member ?
with a_join_date as (
select *
from dannys_diner.members
where dannys_diner.members.customer_id = 'A'),

b_join_date as (
select *
from dannys_diner.members
where dannys_diner.members.customer_id = 'B'),

row_ct as (
select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.sales.product_id,
	row_number() over (partition by customer_id order by order_date desc) as r_n
from dannys_diner.sales
where (dannys_diner.sales.customer_id in (select customer_id from a_join_date)
	  and dannys_diner.sales.order_date < (select join_date from a_join_date))
or (dannys_diner.sales.customer_id in (select customer_id from b_join_date)
	  and dannys_diner.sales.order_date < (select join_date from b_join_date)))

select customer_id, order_date, dannys_diner.menu.product_name
from row_ct
inner join dannys_diner.menu
on dannys_diner.menu.product_id = row_ct.product_id
where r_n = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

with a_join_date as (
select *
from dannys_diner.members
where dannys_diner.members.customer_id = 'A'),

b_join_date as (
select *
from dannys_diner.members
where dannys_diner.members.customer_id = 'B'),

row_ct as (
select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.sales.product_id
from dannys_diner.sales
where (dannys_diner.sales.customer_id in (select customer_id from a_join_date)
	  and dannys_diner.sales.order_date < (select join_date from a_join_date))
or (dannys_diner.sales.customer_id in (select customer_id from b_join_date)
	  and dannys_diner.sales.order_date < (select join_date from b_join_date)))

select customer_id, count(dannys_diner.menu.product_name) as total_items, sum(dannys_diner.menu.price) as amount_spend
from row_ct
inner join dannys_diner.menu
on dannys_diner.menu.product_id = row_ct.product_id
group by customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?

with points as (
select dannys_diner.sales.customer_id, dannys_diner.menu.product_name,
	dannys_diner.menu.price,
case 
	when dannys_diner.menu.product_name in ('curry','ramen') then dannys_diner.menu.price*10
	when dannys_diner.menu.product_name = 'sushi' then dannys_diner.menu.price*10*2
end as points_gained
from dannys_diner.sales
inner join dannys_diner.menu
on dannys_diner.sales.product_id = dannys_diner.menu.product_id)

select customer_id, sum(points_gained) as tot
from points
group by customer_id
order by tot desc;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

with a_join as (
select customer_id, join_date, join_date + interval '7 days' as first_week
from dannys_diner.members
where dannys_diner.members.customer_id = 'A'),

b_join as (
select customer_id, join_date, join_date + interval '7 days' as first_week
from dannys_diner.members
where dannys_diner.members.customer_id = 'B'),

join_date_table as (
select dannys_diner.sales.customer_id, dannys_diner.sales.order_date,dannys_diner.menu.product_name,
	dannys_diner.menu.price,
case
	when dannys_diner.sales.customer_id = 'A' then (select join_date from a_join)
	when dannys_diner.sales.customer_id = 'B' then (select join_date from b_join)
end as join_date
from dannys_diner.sales
inner join dannys_diner.menu
on dannys_diner.sales.product_id = dannys_diner.menu.product_id
where dannys_diner.sales.customer_id in ('A','B')),

first_week_table as (
select customer_id, order_date, product_name, price,join_date, join_date + interval '7 days' as first_week 
from join_date_table),

total as (
select customer_id, order_date, product_name, join_date, first_week,
case 
	when (order_date >= join_date) and (order_date <= first_week) then price*10*2
	when product_name in ('curry','ramen') then price*10
	when product_name = 'sushi' then price*10*2
end as fin
from first_week_table)

select customer_id, sum(fin)
from total
where order_date < '2021-02-01'
group by customer_id;

-- Bonus : Join All The Things
create view join_table_new as 
select dannys_diner.sales.customer_id, dannys_diner.sales.order_date, dannys_diner.menu.product_name,
		dannys_diner.menu.price, 
case 
	when dannys_diner.sales.customer_id in (select dannys_diner.members.customer_id from dannys_diner.members)
	and (dannys_diner.sales.order_date >= dannys_diner.members.join_date) then 'Y'
	else 'N'
end as member
from dannys_diner.sales
left join dannys_diner.members
on dannys_diner.sales.customer_id = dannys_diner.members.customer_id
left join dannys_diner.menu
on dannys_diner.menu.product_id = dannys_diner.sales.product_id
order by customer_id, order_date asc;

-- Bonus : Rank All The Things
create view rank_all as
select customer_id, order_date, product_name, price, member, 
case 
	when member = 'Y' then rank () over (partition by member,customer_id order by order_date asc)	
end as asd
from join_table_new 
order by customer_id, order_date asc;



































