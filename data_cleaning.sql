/*
=====================================================
 Project:   e-commerce-sales-analysis
 Script:    fix_incorrect_dates.sql
 Purpose:   Clean and fix database data issues
 Author:    Mikołaj Kowal
 Date:      2025-09-27
 Notes:
 	- No rows returned by the SELECT statements indicates no inconsistencies or issues were found
 	- To perform the check, uncomment the SELECT statements
=====================================================
*/

USE ecommerce_db;


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


