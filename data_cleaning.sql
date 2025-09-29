/*
=====================================================
 Project:   e-commerce-sales-analysis
 Script:    data_cleaning.sql
 Purpose:   Clean and fix database data issues
 Author:    Mikołaj Kowal
 Date:      2025-09-29
 Notes:
 	- No rows returned by the SELECT statements indicates no inconsistencies or issues were found
 	- To perform the check, uncomment the SELECT statements
=====================================================
*/

USE ecommerce_db;


/*
=====================================================

Identifying duplicate entries in the dataset

=====================================================
*/

-- Customers

-- SELECT 	customer_id, COUNT(*) AS num_of_duplicates
-- FROM	Customers
-- GROUP BY customer_id
-- HAVING	COUNT(*) > 1;

-- SELECT 	email, COUNT(*) AS num_of_duplicates
-- FROM	Customers
-- GROUP BY email
-- HAVING	COUNT(*) > 1;

-- SELECT 	phone_number, COUNT(*) AS num_of_duplicates
-- FROM	Customers
-- GROUP BY phone_number
-- HAVING	COUNT(*) > 1;

-- Reviews

-- SELECT 	review_id, COUNT(*) AS num_of_duplicates
-- FROM	Reviews
-- GROUP BY review_id
-- HAVING	COUNT(*) > 1;

-- SELECT 	review_id, customer_id, product_id, review_date, COUNT(*) AS num_of_duplicates
-- FROM	Reviews
-- GROUP BY review_id, customer_id, product_id, review_date
-- HAVING	COUNT(*) > 1;

-- Products

-- SELECT 	product_id, COUNT(*) AS num_of_duplicates
-- FROM	Products
-- GROUP BY product_id
-- HAVING	COUNT(*) > 1;

-- SELECT 	product_name, category_id, brand, COUNT(*) AS num_of_duplicates
-- FROM	Products
-- GROUP BY product_name, category_id, brand
-- HAVING	COUNT(*) > 1;

-- Categories

-- SELECT 	category_id, COUNT(*) AS num_of_duplicates
-- FROM	Categories
-- GROUP BY category_id
-- HAVING	COUNT(*) > 1;

-- SELECT 	category_name, COUNT(*) AS num_of_duplicates
-- FROM	Categories
-- GROUP BY category_name
-- HAVING	COUNT(*) > 1;

-- Orders

-- SELECT 	order_id, COUNT(*) AS num_of_duplicates
-- FROM	Orders
-- GROUP BY order_id
-- HAVING	COUNT(*) > 1;

-- SELECT 	customer_id, order_date, COUNT(*) AS num_of_duplicates
-- FROM	Orders
-- GROUP BY customer_id, order_date
-- HAVING	COUNT(*) > 1;

-- Order_Items

-- SELECT 	order_item_id, COUNT(*) AS num_of_duplicates
-- FROM	Order_Items
-- GROUP BY order_item_id
-- HAVING	COUNT(*) > 1;

-- SELECT 	order_id, product_id, COUNT(*) AS num_of_duplicates
-- FROM	Order_Items
-- GROUP BY order_id, product_id
-- HAVING	COUNT(*) > 1;

-- Payments

-- SELECT 	payment_id, COUNT(*) AS num_of_duplicates
-- FROM	Payments
-- GROUP BY payment_id
-- HAVING	COUNT(*) > 1;

-- SELECT 	order_id, COUNT(*) AS num_of_duplicates
-- FROM	Payments
-- GROUP BY order_id
-- HAVING	COUNT(*) > 1;

-- Shipping
-- 
-- SELECT 	shipping_id, COUNT(*) AS num_of_duplicates
-- FROM	Shipping
-- GROUP BY shipping_id
-- HAVING	COUNT(*) > 1;
-- 
-- SELECT 	order_id, COUNT(*) AS num_of_duplicates
-- FROM	Shipping
-- GROUP BY shipping_id
-- HAVING	COUNT(*) > 1;


-- Are there differences between 'Order_Items.unit_price' and 'Product.price'?

-- SELECT p.product_id, oi.product_id, p.price, oi.unit_price, p.price - oi.unit_price  
-- FROM Products p INNER JOIN Order_Items oi 
-- ON p.product_id = oi.product_id
-- WHERE p.price - oi.unit_price <> 0;


-- Are total payments different from the sum of product prices times their quantities in orders?
-- 
-- WITH order_payments AS (SELECT 	p.order_id,
-- 								p.amount AS payment_amount,
-- 								SUM(oi.unit_price * oi.quantity) AS order_total
-- 						FROM 	Orders o INNER JOIN Order_Items oi ON o.order_id = oi.order_id 
-- 								INNER JOIN Payments p ON o.order_id = p.order_id
-- 						GROUP BY p.order_id, p.amount)
-- SELECT	order_id,
-- 		payment_amount,
-- 		order_total,
-- 		payment_amount - order_total AS difference
-- FROM 	order_payments
-- WHERE	payment_amount - order_total > 0
-- ORDER BY order_id;


/*
=====================================================

The following statements perform necessary updates to clean and standardize the dataset

=====================================================
*/

-- Remove duplicates in 'Order_Items' where 'order_id' and 'product_id' are the same,
-- keeping only the row with the lowest 'order_item_id'

START TRANSACTION;

DELETE	oi1
FROM 	Order_Items oi1
		INNER JOIN (
					SELECT 	order_item_id,
							ROW_NUMBER() OVER (PARTITION BY order_id, product_id ORDER BY order_item_id) AS row_nums
					FROM	Order_Items
				   ) AS oi2 ON oi1.order_item_id = oi2.order_item_id
WHERE oi2.row_nums > 1;

COMMIT;



-- Fix inconsistencies in payments for orders

START TRANSACTION;

UPDATE 	Orders o 
		INNER JOIN Payments p ON o.order_id = p.order_id
		INNER JOIN (SELECT	order_id,
							SUM(unit_price * quantity) AS order_total
					FROM	Order_Items o
					GROUP BY order_id
		) AS order_totals
		ON o.order_id = order_totals.order_id
SET		p.amount = order_totals.order_total
WHERE	p.amount <> order_totals.order_total;
		
COMMIT;


