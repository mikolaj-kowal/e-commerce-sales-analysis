/*
=====================================================
 Project:   e-commerce-sales-analysis
 Script:    fix_incorrect_dates.sql
 Purpose:   Correct date values in the AI-generated e-commerce dataset to make them more realistic for this kind of project.
 Author:    Mikołaj Kowal
 Date:      2025-09-26
=====================================================
*/

USE ecommerce_db;
 
/*
-- Aims of the update statements:
-- Ensure date values in specific columns follow these rules:
--
-- 'Orders.order_date'        -> random values between '2024-09-01' and '2025-08-31'
-- 'Orders.updated_at'        -> random values between 'Orders.order_date' + 2 days
-- 'Customers.signup_date'    -> earlier than the first order date for each customer
-- 'Products.created_at'      -> earlier than the first 'Orders.order_date' for each product
-- 'Products.updated_at'      -> random dates between 'Products.created_at' and 15 days later
-- 'Payments.payment_date'    -> random dates between 'Orders.order_date' and 2 days later
-- 'Shipping.ship_date'       -> random dates after the later of 'Orders.updated_at' 
--                               or 'Payments.payment_date' + 1 day
-- 'Shipping.delivery_date'   -> random dates between 'Shipping.ship_date' and 6 days later
-- 'Reviews.review_date'	  -> random dates after related 'Orders.order_date' of the product by customer and today
 */



-- Update 'Orders.order_date' to random values between '2024-09-01' and '2025-08-31'.
UPDATE 	Orders 
SET 	order_date = TIMESTAMP('2024-09-01')
					 + INTERVAL FLOOR(0 + RAND() * 364) DAY
					 + INTERVAL FLOOR(0 + RAND() * 86400) SECOND
WHERE order_date NOT BETWEEN '2024-09-01' AND '2025-08-31';



-- Update 'Orders.updated_at' to random values between 'Orders.order_date' + 2 days.
UPDATE 	Orders o 
SET updated_at = order_date
				 + INTERVAL FLOOR(0 + RAND() * 1) DAY
				 + INTERVAL FLOOR(0 + RAND() * 86400) SECOND;



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
-- The new date will be a random number of days between 20 days before and the first order date
UPDATE 	Customers c
SET 	c.signup_date = (SELECT	MIN(o.order_date) - INTERVAL FLOOR(0 + RAND() * 20) DAY
						 FROM 	Orders o
						 WHERE 	c.customer_id = o.customer_id
									AND c.signup_date >= o.order_date);



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



-- Update 'Products.updated_at' to a random date between 'Products.created_at' and 15 days later
UPDATE 	Products
SET		updated_at = created_at
			 + INTERVAL FLOOR(0 + RAND() * 14) DAY + INTERVAL FLOOR(0 + RAND() * 86400) SECOND
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



-- Update 'Shipping.delivery_date' to a random dates between 'Shipping.ship_date' and 6 days later
UPDATE	Shipping
SET 	delivery_date = ship_date
			+ INTERVAL FLOOR(0 + RAND() * 3) DAY
			+ INTERVAL FLOOR(0 + RAND() * 86400) SECOND
WHERE	delivery_date NOT BETWEEN ship_date
		AND ship_date + INTERVAL 6 DAY;



-- Update 'Reviews.order_id' to a random order of the product placed by that customer
UPDATE 	Reviews r1
		INNER JOIN (SELECT	r2.review_id AS review_id, c.customer_id, p.product_id, o.order_id AS order_id,
							ROW_NUMBER() OVER (PARTITION BY r2.review_id ORDER BY RAND()) AS row_num		
					FROM 	Reviews r2
							INNER JOIN Products p ON r2.product_id = p.product_id 
							INNER JOIN Customers c ON r2.customer_id = c.customer_id
							INNER JOIN Order_Items oi ON p.product_id = oi.product_id 
							INNER JOIN Orders o ON o.order_id = oi.order_id
					WHERE	o.customer_id = r2.customer_id
							AND oi.product_id = r2.product_id) AS t1
		ON r1.review_id = t1.review_id
SET		r1.order_id = t1.order_id;

-- Update 'Reviews.review_date' to a random date between the related 'Orders.order_date' and 50 days later
UPDATE	Reviews r
		INNER JOIN Orders o ON r.order_id = o.order_id
SET		r.review_date = o.order_date + INTERVAL FLOOR(0 + RAND() * 50) DAY
WHERE	r.review_date NOT BETWEEN o.order_date AND DATE_ADD(o.order_date, INTERVAL 50 DAY);



-- Final validation check
-- should return all zeroes
SELECT
		-- Order dates checks
		SUM(CASE WHEN o.order_date NOT BETWEEN '2024-09-01' AND '2025-08-31' THEN 1 ELSE 0 END) AS invalid_orders,
		-- Order update dates check
		SUM(CASE WHEN o.updated_at NOT BETWEEN o.order_date AND DATE_ADD(o.order_date, INTERVAL 2 DAY) THEN 1 ELSE 0 END) AS invalid_orders_updated_at,
		-- Customer signup must occur before an order
		SUM(CASE WHEN c.signup_date >= o.order_date THEN 1 ELSE 0 END) AS invalid_signup_dates,
		-- Products creation date check
		SUM(CASE WHEN p.created_at >= o.order_date THEN 1 ELSE 0 END) AS invalid_product_creating_date,
		-- Products updated date check
		SUM(CASE WHEN p.updated_at NOT BETWEEN p.created_at AND DATE_ADD(p.created_at, INTERVAL 15 DAY) THEN 1 ELSE 0 END) AS invalid_product_updated_date,
		-- Payment dates check
		SUM(CASE WHEN ps.payment_date NOT BETWEEN o.order_date AND DATE_ADD(o.order_date, INTERVAL 2 DAY) THEN 1 ELSE 0 END) AS invalid_payment_date,
		-- Ship dates check
		SUM(CASE WHEN 
			s.ship_date NOT BETWEEN o.updated_at AND DATE_ADD(o.updated_at, INTERVAL 1 DAY)
			AND s.ship_date NOT BETWEEN ps.payment_date AND DATE_ADD(ps.payment_date, INTERVAL 1 DAY) THEN 1 ELSE 0 END) AS invalid_ship_date,
		-- Delivery date checks
		SUM(CASE WHEN s.delivery_date NOT BETWEEN s.ship_date AND DATE_ADD(s.ship_date, INTERVAL 6 DAY) THEN 1 ELSE 0 END) AS invalid_delivery_date,
		-- Review date checks
		SUM(CASE WHEN r.review_date NOT BETWEEN o.order_date AND DATE_ADD(o.order_date, INTERVAL 50 DAY) THEN 1 ELSE 0 END) AS invalid_review_dates
FROM	Orders o 
		LEFT JOIN Shipping s ON s.order_id = o.order_id
		LEFT JOIN Order_Items oi ON o.order_id = oi.order_id
		LEFT JOIN Products p ON oi.product_id = p.product_id
		LEFT JOIN Customers c ON o.customer_id = c.customer_id
		LEFT JOIN Payments ps ON o.order_id = ps.order_id
		LEFT JOIN Reviews r ON o.order_id = r.order_id;
