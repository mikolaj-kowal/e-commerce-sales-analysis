/*
=====================================================
 Project:   e-commerce-sales-analysis
 Script:    fix_incorrect_dates.sql
 Purpose:   Correct date values in the AI-generated e-commerce dataset to make them more realistic for this kind of project.
 Author:    Mikołaj Kowal
 Date:      2025-09-20
=====================================================
*/

USE ecommerce_db;

-- Check: Order dates should be random values between '2024-09-01' and '2025-08-31'.
-- The query returns values that do not meet this requirement.
SELECT 	order_id,
		order_date
FROM 	Orders o
WHERE 	order_date NOT BETWEEN '2024-09-01' AND '2025-08-31';

-- Update 'Orders.order_date' to random values between '2024-09-01' and '2025-08-31'.
UPDATE 	Orders 
SET 	order_date = TIMESTAMP('2024-09-01')
					 + INTERVAL FLOOR(0 + RAND() * 364) DAY
					 + INTERVAL FLOOR(0 + RAND() * 86400) SECOND
WHERE order_date NOT BETWEEN '2024-09-01' AND '2025-08-31';

-- Verify the update
SELECT 	order_id,
		order_date
FROM 	Orders o
WHERE 	order_date NOT BETWEEN '2024-09-01' AND '2025-08-31';



-- Check: 'Orders.updated_at' dates should be random values between 'Orders.order_date' + 2 days.
SELECT 	order_id,
		order_date,
		updated_at
FROM 	Orders
WHERE 	updated_at < order_date
		OR updated_at > order_date + INTERVAL 2 DAY;

-- Update 'Orders.updated_at' to random values between 'Orders.order_date' + 2 days.
UPDATE 	Orders o 
SET updated_at = order_date
				 + INTERVAL FLOOR(0 + RAND() * 1) DAY
				 + INTERVAL FLOOR(0 + RAND() * 86400) SECOND;

-- Verify the update
SELECT 	order_id,
		order_date,
		updated_at
FROM 	Orders
WHERE 	updated_at < order_date
		OR updated_at > order_date + INTERVAL 2 DAY;



-- Check: Customer signup dates must be earlier than the first order date made by them.
-- The difference between 'Customers.signup_date' and 'Orders.order_date' should always be positive.
-- Displays rows where the difference is zero or negative
WITH first_order_dates AS (	SELECT 	c.customer_id,
									c.signup_date,
									MIN(o.order_date) AS first_order_date
							FROM 	Customers c INNER JOIN Orders o ON c.customer_id = o.customer_id
							GROUP BY c.customer_id, c.signup_date)
SELECT 	customer_id,
		signup_date,
		first_order_date, 
		TIMESTAMPDIFF(SECOND, signup_date, first_order_date) AS timestamp_diff
FROM 	first_order_dates
WHERE	signup_date >= first_order_date;


-- Update 'Customer.signup_date' to a date earlier than the customer's first order
-- The new date will be a random number of days between 20 days before and the order date
UPDATE 	Customers c
SET 	c.signup_date = (SELECT	MIN(o.order_date) - INTERVAL FLOOR(0 + RAND() * 20) DAY
						 FROM 	Orders o
						 WHERE 	c.customer_id = o.customer_id
									AND c.signup_date >= o.order_date);

-- Verify the update
SELECT	c.signup_date,
		o.order_date,
		TIMESTAMPDIFF(MINUTE, c.signup_date, o.order_date) AS timestamp_diff
FROM 	Customers c INNER JOIN Orders o ON c.customer_id = o.customer_id
WHERE	c.signup_date >= o.order_date;



-- Check: 'Products.created_at' should be earlier than the first 'Orders.order_date' for each product
SELECT 	p.product_id,
		p.created_at,
		o.order_id,
		o.order_date
FROM 	Products p
		INNER JOIN Order_Items oi ON p.product_id = oi.product_id
		INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE	p.created_at >= o.order_date;

-- Update 'Products.created_at' to a date earlier than the first order
-- The new date will be a random number of days between 50 days before and the date of the first order
UPDATE 	Products p
		INNER JOIN Order_Items oi ON p.product_id = oi.product_id
		INNER JOIN Orders o ON oi.order_id = o.order_id
SET 	p.created_at = o.order_date
		- INTERVAL FLOOR(1 + RAND() * 49) DAY
		- INTERVAL FLOOR(0 + RAND() * 86400) SECOND
WHERE 	o.order_date = (SELECT	MIN(o1.order_date)
						FROM 	Orders o1 INNER JOIN Order_Items oi1 ON o1.order_id = oi1.order_id
						WHERE 	oi1.product_id = p.product_id);

-- Verify the update
SELECT 	p.product_id,
		p.created_at,
		o.order_id,
		o.order_date
FROM 	Products p
		INNER JOIN Order_Items oi ON p.product_id = oi.product_id
		INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE	p.created_at >= o.order_date;



-- Update 'Products.updated_at' to a random date between 'Products.created_at' and 15 days later
UPDATE 	Products
SET		updated_at = created_at
			 + INTERVAL FLOOR(0 + RAND() * 14) DAY + INTERVAL FLOOR(0 + RAND() * 86400) SECOND
WHERE	updated_at NOT BETWEEN created_at 
		AND created_at + INTERVAL 15 DAY;

-- Verify the update
SELECT	product_id,
		created_at,
		updated_at
FROM 	Products
WHERE	updated_at NOT BETWEEN created_at 
		AND created_at + INTERVAL 15 DAY;



-- Update 'Payments.payment_date' to a random dates between 'Orders.order_date' and 2 days later
UPDATE 	Orders o 
		INNER JOIN Payments p ON o.order_id = p.order_id
SET 	p.payment_date = o.order_date
			 + INTERVAL FLOOR(0 + RAND() * 1) DAY
			 + INTERVAL FLOOR(0 + RAND() * 86400) SECOND
WHERE	p.payment_date NOT BETWEEN o.order_date
		AND o.order_date + INTERVAL 2 DAY; 

-- Verify the update
SELECT 	p.payment_id,
		p.payment_date,
		o.order_id,
		o.order_date,
		TIMESTAMPDIFF(DAY, o.order_date, p.payment_date)
FROM 	Orders o
		INNER JOIN Payments p ON o.order_id = p.order_id
WHERE	p.payment_date NOT BETWEEN o.order_date
		AND o.order_date + INTERVAL 2 DAY;



-- Update 'Shipping.ship_date' to a random date after the later of 'Orders.updated_at' or 'Payments.payment_date' + 1 day
UPDATE 	Shipping s
		INNER JOIN Orders o ON o.order_id = s.order_id 
		INNER JOIN Payments p ON o.order_id = p.order_id
SET		s.ship_date = p.payment_date + INTERVAL 1 DAY
WHERE	p.payment_date >= o.updated_at;

UPDATE 	Shipping s
		INNER JOIN Orders o ON o.order_id = s.order_id 
		INNER JOIN Payments p ON o.order_id = p.order_id
SET		s.ship_date = o.updated_at + INTERVAL 1 DAY
WHERE	o.updated_at > p.payment_date;


-- Verify the update
SELECT	o.order_date, p.payment_date, s.ship_date,
		TIMESTAMPDIFF(DAY, p.payment_date, s.ship_date)
FROM 	Payments p INNER JOIN Orders o ON p.order_id = o.order_id 
		INNER JOIN Shipping s ON o.order_id = s.order_id;



-- Update 'Shipping.delivery_date' to a random dates between 'Shipping.ship_date' and 6 days later
UPDATE	Shipping
SET 	delivery_date = ship_date
			+ INTERVAL FLOOR(0 + RAND() * 3) DAY
			+ INTERVAL FLOOR(0 + RAND() * 86400) SECOND
WHERE	delivery_date NOT BETWEEN ship_date
		AND ship_date + INTERVAL 6 DAY;

-- Verify thee update
SELECT	ship_date,
		delivery_date,
		TIMESTAMPDIFF(DAY, ship_date, delivery_date)
FROM	Shipping
WHERE 	delivery_date NOT BETWEEN ship_date
		AND ship_date + INTERVAL 6 DAY;
