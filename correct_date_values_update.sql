SELECT	c.signup_date AS c_signup_date,
		p.created_at AS p_created_at,
		p.updated_at AS p_updated_at,
		o.order_date AS o_order_date, --
		o.updated_at AS o_updated_at,
		ps.payment_date AS ps_payment_date,
		s.ship_date AS s_ship_date,
		s.delivery_date AS s_delivery_date
FROM 	Products p 
		INNER JOIN Order_Items oi ON p.product_id = oi.product_id 
		INNER JOIN Orders o ON oi.order_id = o.order_id 
		INNER JOIN Payments ps ON o.order_id = ps.order_id 
		INNER JOIN Shipping s ON o.order_id = s.order_id
		INNER JOIN Customers c ON c.customer_id = o.customer_id;


SELECT	o.order_id,
		c.signup_date AS c_signup_date,
		o.order_date AS o_order_date,
		DATEDIFF(c.signup_date, o.order_date) AS date_
FROM 	Orders o
		INNER JOIN Customers c ON c.customer_id = o.customer_id
ORDER BY DATEDIFF(c.signup_date, o.order_date) DESC;



UPDATE	Orders o
		INNER JOIN Customers c ON c.customer_id = o.customer_id 
SET 	c.signup_date = o.order_date - interval 1 day
WHERE	DATEDIFF(c.signup_date, o.order_date) > 0;



-- Set up 'order_date' values as random dates between '2024-09-01' and '2025-08-31'

SELECT DATE('2024-09-01') + INTERVAL FLOOR(1 + RAND() * 9 ) DAY;

UPDATE Orders 
SET order_date = TIMESTAMP('2024-09-01')
					+ INTERVAL FLOOR(0 + RAND() * 365) DAY
					+ INTERVAL FLOOR(0 + RAND() * 86400) SECOND;

SELECT TIMESTAMP('2024-09-01') + INTERVAL FLOOR(0 + RAND() * 4) DAY AS ts;

SELECT order_date
FROM Orders
ORDER BY order_date;



-- Set up 'Products.created_at' values as random dates before first value in 'Orders.order_date' for that product

SELECT TIMESTAMPDIFF(MINUTE, o.order_date, p.created_at)
FROM Products p
		INNER JOIN Order_Items oi ON p.product_id = oi.product_id
		INNER JOIN Orders o ON oi.order_id = o.order_id;


SELECT customer_id, MIN(order_date)
FROM Orders
GROUP BY customer_id
ORDER BY MIN(order_date) DESC;


SELECT 
FROM Products p
		INNER JOIN Order_Items oi ON p.product_id = oi.product_id
		INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_date = (	SELECT MIN(o1.order_date)
						FROM Orders o1 INNER JOIN Order_Items oi1 ON o1.order_id = oi1.order_id
						WHERE oi1.product_id = p.product_id);


UPDATE Products p
		INNER JOIN Order_Items oi ON p.product_id = oi.product_id
		INNER JOIN Orders o ON oi.order_id = o.order_id
SET p.created_at = o.order_date
		- INTERVAL FLOOR(1 + RAND() * 50) DAY
		- INTERVAL FLOOR(0 + RAND() * 86400) SECOND
WHERE o.order_date = (	SELECT MIN(o1.order_date)
						FROM Orders o1 INNER JOIN Order_Items oi1 ON o1.order_id = oi1.order_id
						WHERE oi1.product_id = p.product_id);


WITH date_diffs AS (SELECT o.order_date - p.created_at > 0 AS date_diff
					FROM Products p
							INNER JOIN Order_Items oi ON p.product_id = oi.product_id
							INNER JOIN Orders o ON oi.order_id = o.order_id)
SELECT date_diff, COUNT(*) 
FROM date_diffs
GROUP BY date_diff;


SELECT p.product_id, p.created_at, o.order_date
FROM Products p
		INNER JOIN Order_Items oi ON p.product_id = oi.product_id
		INNER JOIN Orders o ON oi.order_id = o.order_id;

-- Set up 'Customers.signup_date' values as random dates before first value in 'Orders.order_date' for that customer

SELECT 	c.signup_date,
		FIRST_VALUE(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS first_order_date
FROM Customers c INNER JOIN Orders o ON c.customer_id = o.customer_id;

SELECT 	c.signup_date,
		MIN(o.order_date)
FROM Customers c INNER JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.signup_date;


START TRANSACTION;

UPDATE 	Customers c
		INNER JOIN Orders o ON c.customer_id = o.customer_id
SET 	c.signup_date = FIRST_VALUE(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date);
- INTERVAL FLOOR(0 + RAND() * 20);


START TRANSACTION;

UPDATE 	Customers c
SET 	c.signup_date = (	SELECT MIN(o.order_date) - INTERVAL FLOOR(0 + RAND() * 20) DAY
							FROM Orders o
							WHERE c.customer_id = o.customer_id);

SELECT 	TIMESTAMPDIFF(MINUTE, c.signup_date, o.order_date)
FROM Customers c INNER JOIN Orders o ON c.customer_id = o.customer_id;


SELECT 	o.order_date, c.signup_date
FROM Customers c INNER JOIN Orders o ON c.customer_id = o.customer_id;


-- Set up 'Products.updated_at' values as random dates after value 'Products.created_at'

UPDATE Products p
SET updated_at = created_at + INTERVAL FLOOR(0 + RAND() * 15) DAY + INTERVAL FLOOR(0 + RAND() * 86400) SECOND;


-- Set up 'Orders.updated_at' values as random dates between 'Orders.order_date' + 2 days

SELECT order_date, updated_at
FROM Orders;

UPDATE 	Orders o 
SET updated_at = order_date
				+ INTERVAL FLOOR(0 + RAND() * 1) DAY
				+ INTERVAL FLOOR(0 + RAND() * 86400) SECOND;

SELECT order_date, updated_at, TIMESTAMPDIFF(MINUTE, order_date, updated_at)
FROM Orders;


-- Set up 'Payments.payment_date' values as random dates after 'Orders.order_date' + 2 days

SELECT o.order_date, p.payment_date, TIMESTAMPDIFF(MINUTE, o.order_date, p.payment_date)
FROM Orders o INNER JOIN Payments p ON o.order_id = p.order_id;


UPDATE 	Orders o INNER JOIN Payments p ON o.order_id = p.order_id
SET p.payment_date = o.order_date
				+ INTERVAL FLOOR(0 + RAND() * 1) DAY
				+ INTERVAL FLOOR(0 + RAND() * 86400) SECOND;


-- Set up 'Shipping.ship_date' values as random dates after 'Orders.updated_at' or 'Payments.payment_date' + 1 day
	-- depends on which is later

SELECT	o.order_date, p.payment_date, s.ship_date
FROM 	Payments p INNER JOIN Orders o ON p.order_id = o.order_id 
		INNER JOIN Shipping s ON o.order_id = s.order_id;

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

SELECT	o.order_date, TIMESTAMPDIFF(MINUTE, p.payment_date, s.ship_date) > 0 AS check_diffs
FROM 	Payments p INNER JOIN Orders o ON p.order_id = o.order_id 
		INNER JOIN Shipping s ON o.order_id = s.order_id;

-- Set up 'Shipping.delivery_date' values as random dates after 'Shipping.ship_date' + 4 days

UPDATE Shipping
SET delivery_date = ship_date + INTERVAL FLOOR(0 + RAND() + 4) DAY;