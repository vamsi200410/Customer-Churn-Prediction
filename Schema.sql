-- Zomata Data Analysis using Sql

create table customers(
	customer_id int primary key,
	customer_name varchar(25),
	reg_date Date
);


create table restaurants(
	restaurant_id int primary key,
	restaurant_name varchar(55),
	city varchar(15),
	opening_hours varchar(55)
);

create table orders(
	order_id int primary key,
	customer_id int,--this is from customer
	restaurant_id int,-- this is from restuarants table
	order_item varchar(55),
	order_date Date,
	order_time Time,
	order_status varchar(25),
	total_amount float
);

alter table orders
add constraint fk_customers
foreign key (customer_id) references customers(customer_id);

alter table orders
add constraint fk_restaurants
foreign key (restaurant_id) references restaurants(restaurant_id);

create table riders(
	rider_id int primary key,
	rider_name varchar(55),
	sign_up Date
);

drop table if exists deliveries;
create table deliveries(
	delivery_id int primary key,
	order_id int,--this is from order
	delivery_status varchar(35),
	delivery_time Time,
	rider_id int, --this is from riders
	constraint fk_riders foreign key (rider_id) references riders(rider_id),
	constraint fk_orders foreign key (order_id) references orders(order_id)
);

--End od Schema

