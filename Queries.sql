--EDA

select * from customers;
select * from restaurants;
select * from orders;
select * from riders;
select * from deliveries;


-- Handling null values
select count(*) from customers
where reg_date is null or customer_name is null;


select count(*) from restaurants
where restaurant_name is null or city is null or opening_hours is null;

select count(*) from orders
where order_item is null or order_date is null or total_amount is null or order_time is null or order_status is null;

select count(*) from riders
where rider_name is null or sign_up is null;

select count(*) from deliveries
where restaurant_name is null or city is null or opening_hours is null;


--Analysis & Reports

-- Q.1
-- Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" in the last 1 year.

select * from 
(select c.customer_id,c.customer_name,o.order_item,count(order_id) as total_orders,dense_rank() over(order by count(*) desc) as rank from customers as c
join 
orders as o
on o.customer_id=c.customer_id
where c.customer_name='Arjun Mehta' and o.order_date >= CURRENT_DATE - interval '5 Year'
group by 1,2,3
order by 1,4 desc) as t1
where rank<=5;


-- 2. Popular Time Slots
-- Question: Identify the time slots during which the most orders are placed. based on 2-hour intervals.

--Approach

select
	case 
		when extract(hour from order_time) between 0 and 1 then '00:00- 02:00'
		when extract(hour from order_time)  between 2 and 3 then '02:00- 04:00'
		when extract(hour from order_time)  between 4 and 5 then '04:00- 06:00'
		when extract(hour from order_time)  between 6 and 7 then '06:00- 08:00'
		when extract(hour from order_time)  between 8 and 9 then '08:00- 10:00'
		when extract(hour from order_time)  between 10 and 11 then '10:00- 12:00'
		when extract(hour from order_time)  between 12 and 13 then '12:00- 14:00'
		when extract(hour from order_time)  between 14 and 15 then '14:00- 16:00'
		when extract(hour from order_time)  between 16 and 17 then '16:00- 18:00'
		when extract(hour from order_time)  between 18 and 19 then '18:00- 20:00'
		when extract(hour from order_time)  between 20 and 21 then '20:00- 22:00'
		when extract(hour from order_time) between 22 and 23 then '22:00- 00:00'
	end as time_slot,
	count(order_id) as order_count
from orders
group by time_slot
order by order_count desc;

--approact 2

select
	floor(extract(hour from order_time)/2)*2 as start_time,
	floor(extract(hour from order_time)/2)*2 +2 as end_time,
	count(*) as order_count
from orders
group by start_time,end_time
order by order_count desc;


-- 3. Order Value Analysis
-- Question: Find the average order value per customer who has placed more than 750 orders.
-- Return customer_name, and aov(average order value)


select c.customer_name,avg(o.total_amount) as aov 
from orders o join customers c
on c.customer_id=o.customer_id
group by 1
having count(order_id)>750;


-- 4. High-Value Customers
-- Question: List the customers who have spent more than 100K in total on food orders.
-- return customer_name, and customer_id!
select c.customer_name,sum(o.total_amount) as total_spent
from orders o join customers c
on c.customer_id=o.customer_id
group by 1
having sum(o.total_amount) >100000;


-- 5. Orders Without Delivery
-- Question: Write a query to find orders that were placed but not delivered. 
-- Return each restuarant name, city and number of not delivered orders 


SELECT 
	r.restaurant_name,
	COUNT(o.order_id) as cnt_not_delivered_orders
FROM orders as o
LEFT JOIN 
restaurants as r
ON r.restaurant_id = o.restaurant_id
LEFT JOIN
deliveries as d
ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY 1
ORDER BY 2 DESC;


-- Q. 6
-- Restaurant Revenue Ranking: 
-- Rank restaurants by their total revenue from the last year, including their name, 
-- total revenue, and rank within their city.
select 
	r.city,r.restaurant_name,
	sum(o.total_amount) as revenue,
	rank() over(partition by r.city order by sum(o.total_amount) desc) as rank
from orders as o
inner join 
restaurants as r
on r.restaurant_id=o.restaurant_id
where o.order_date >= CURRENT_DATE - Interval'1 Year'
group by 1,2
order by 1,3 desc;

-- Q. 7
-- Most Popular Dish by City: 
-- Identify the most popular dish in each city based on the number of orders.

with most_pop_dish_per_city
as(
select r.city,o.order_item,count(o.order_id) as total_orders,rank() over(partition by r.city order by count(order_id) desc) as rank from orders as o
inner join restaurants as r
on r.restaurant_id=o.restaurant_id
group by 1,2
order by 1,3 desc)
select city,order_item from most_pop_dish_per_city
where rank =1;



-- Q.8 Customer Churn: 
-- Find customers who haven’t placed an order in 2024 but did in 2023.

select distinct customer_id 
from orders 
	where 
	extract(year from order_date)=2023
	and customer_id not in (
							select distinct customer_id from orders where extract(year from order_date)=2024);



-- Q.9 Cancellation Rate Comparison: 
-- Calculate and compare the order cancellation rate for each restaurant between the 
-- current year and the previous year.

with cancel_ratio as
(
select 
	o.restaurant_id,
	count(o.order_id) as total_orders,
	count(case when d.delivery_id is null then 1 end) as not_delivered
from orders as o
left join 
deliveries as d
on o.order_id=d.order_id
where extract(year from order_date)=2023
group by 1
),
cancel_ratio_2024 as
(
		select 
			o.restaurant_id,
			count(o.order_id) as total_orders,
			count(case when d.delivery_id is null then 1 end) as not_delivered
		from orders as o
		left join 
		deliveries as d
		on o.order_id=d.order_id
		where extract(year from order_date)=2024
		group by 1
),
last_year as
(
	select 
		restaurant_id,
		total_orders,
		not_delivered,
		round(not_delivered::numeric/total_orders::numeric*100,2) 
	as cancel_ratio from cancel_ratio
),
current_year_date as
(
	select 
		restaurant_id,
		total_orders,
		not_delivered,
		round(not_delivered::numeric/total_orders::numeric*100,2) 
	as cancel_ratio from cancel_ratio_2024
)
select 
	c.restaurant_id,
	c.cancel_ratio as current_year,
	l.cancel_ratio as last_year
from current_year_date as c
join
last_year as l
on c.restaurant_id=l.restaurant_id


-- Q.10 Rider Average Delivery Time: 
-- Determine each rider's average delivery time.

SELECT 
    d.rider_id,
    AVG(
        EXTRACT(EPOCH FROM (
            d.delivery_time - o.order_time +
            CASE 
                WHEN d.delivery_time < o.order_time 
                THEN INTERVAL '1 day'
                ELSE INTERVAL '0 day'
            END
        )) / 60
    ) AS avg_delivery_time_minutes
FROM orders o
JOIN deliveries d 
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
GROUP BY d.rider_id;


-- Q.11 Monthly Restaurant Growth Ratio: 
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining

with growth_ratio
as(
select 
	o.restaurant_id,
	to_char(o.order_date,'mm-yy') as month,
	count(o.order_id) as cnt_orders,
	lag(count(o.order_id),1) over(partition by o.restaurant_id order by to_char(o.order_date,'mm-yy')) as prev_month_order
from orders as o
inner join
deliveries as d
on o.order_id=d.delivery_id
where d.delivery_status='Delivered'
group by 1,2
order by 1,2
)
select restaurant_id,
	month,cnt_orders,prev_month_order,round((cnt_orders::numeric-prev_month_order::numeric)/prev_month_order::numeric*100,2) as growth_ratio from growth_ratio;

-- Q.12 Customer Segmentation: 
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending 
-- compared to the average order value (AOV). If a customer's total spending exceeds the AOV, 
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's 
-- total number of orders and total revenue

select 
	customer_level,
	sum(total_orders) as total_order,
	sum(total_amount) as total_revenue
from(
select 
	customer_id,
	sum(total_amount) as total_amount,
	count(order_id) as total_orders,
	case when 
		sum(total_amount) >(select avg(total_amount)from orders) then 'GOLD'
	else
		'SILVER'
	end as customer_level
from orders
group by customer_id)
group by customer_level;


-- Q.13 Rider Monthly Earnings: 
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.

select 
	d.rider_id,
	to_char(o.order_date,'mm-yy') as month,
	sum(o.total_amount) as total_revenue,
	sum(o.total_amount)*0.08 as riders_monthly_earning
from orders as o
join deliveries as d
on o.order_id=d.delivery_id
group by 1,2
order by 1,2 desc


-- Q.14 Rider Ratings Analysis: 
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
-- riders receive this rating based on delivery time.
-- If orders are delivered less than 15 minutes of order received time the rider get 5 star rating,
-- if they deliver 15 and 20 minute they get 4 star rating 
-- if they deliver after 20 minute they get 3 star rating.


select 
	rider_id,
	stars,
	count(*) as total_stars
from(
select 
	rider_id,
	delivery_time_1,
	case 
		when delivery_time_1<15 then '5 star'
		when delivery_time_1 between 15 and 20 then '4 Star'
		else '3 Star'
	end as stars
from(
	select 
		o.order_id,
		o.order_time,
		d.delivery_time,
		d.rider_id,
		extract(epoch from (d.delivery_time-o.order_time+ case when d.delivery_time<o.order_time then interval '1 day' else interval '0 day' end))/60 as delivery_time_1
	from orders as o
	join deliveries as d
	on d.order_id=o.order_id
	where d.delivery_status='Delivered'
) as t1
) as t2
group by 1,2
order by 1,3 desc;


-- Q.15 Order Frequency by Day: 
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.


select *
from(
select 
	r.restaurant_name,
	to_char(o.order_date,'Day') as day,
	count(o.order_id) as total_order,
	rank() over(partition by r.restaurant_name order by count(o.order_id) desc) as rank
from 
orders as o
join 
restaurants as r
on o.restaurant_id=r.restaurant_id
group by 1,2
order by 1,3 desc
) as t1
where rank=1;


 -- Q.16 Customer Lifetime Value (CLV): 
-- Calculate the total revenue generated by each customer over all their orders.

select c.customer_id,
		c.customer_name,
	sum(o.total_amount) as clv 
from orders as o
join customers as c
on o.customer_id=c.customer_id
group by 1,2;


-- Q.17 Monthly Sales Trends: 
-- Identify sales trends by comparing each month's total sales to the previous month.

select 
	extract(year from order_date) as year,
	extract(month from order_date) as month,
	sum(total_amount) as total_sales,
	lag(sum(total_amount),1) over(order by extract(year from order_date),extract(month from order_date)) as prev_month_sales
from orders
group by 1,2
order by 1,2;


-- Q.18 Rider Efficiency: 
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.
with delivery_table
as
(
	select
		d.rider_id,
		extract(epoch from (d.delivery_time-o.order_time+ 
		case when d.delivery_time<o.order_time then interval '1 day' else interval '0 day' end))/60 as time_to_deliver
	from orders as o
	join deliveries as d
	on o.order_id = d.order_id
	where d.delivery_status='Delivered'
),
riders_time
as(
	select 
		rider_id, 
		avg(time_to_deliver) as avg_delivery_time
	from delivery_table
	group by 1
)
select min(avg_delivery_time),max(avg_delivery_time) from riders_time



-- Q.19 Order Item Popularity: 
-- Track the popularity of specific order items over time and identify seasonal demand spikes.

select 
	order_item,
	season,
	count(order_id) as total_order
from(
select
	*,
	extract(month from order_date) as month,
	case 
		when extract(month from order_date) between 4 and 6 then 'Spring'
		when extract(month from order_date) > 6 and extract(month from order_date) < 9 then 'Summer'
		else 'Winter'
		end as season
from orders
)
group by 1,2
order by 1,3 desc;

-- Q.20 Rank each city based on the total revenue for last year 2023 


SELECT 
	r.city,
	SUM(total_amount) as total_revenue,
	RANK() OVER(ORDER BY SUM(total_amount) DESC) as city_rank
FROM orders as o
JOIN
restaurants as r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1;

