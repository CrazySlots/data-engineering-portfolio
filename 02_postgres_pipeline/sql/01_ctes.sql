-- 
-- 1. VOLUME AND QUANTITY

--

-- What is the average number of items per order?

WITH item_count as (
	select order_id,
	COUNT(order_item_id) AS items
	from raw.ORDER_ITEMS 
	group by order_id
)

select ROUND(AVG(items),2) AS avg_items_per_order
from ITEM_COUNT;


-- 
-- Which product category is the best-selling?
-- 

SELECT
    P.PRODUCT_CATEGORY_NAME,
    COUNT(DISTINCT(OI.ORDER_ID) ) AS total_orders,
    COUNT(OI.PRODUCT_ID) AS total_items
FROM
    raw.ORDER_ITEMS OI
LEFT JOIN raw.PRODUCTS P 
ON
    oi.PRODUCT_ID = p.PRODUCT_ID
WHERE p.product_category_name IS NOT NULL
GROUP BY
    p.PRODUCT_CATEGORY_NAME
ORDER BY
    total_orders DESC
LIMIT 10;
--
-- Which are the 5 states with the highest sales?
--

WITH order_location AS (
    SELECT
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS orders_by_state
    FROM raw.orders o
    JOIN raw.customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_state
),
total_orders AS (
    SELECT SUM(orders_by_state) AS grand_total
    FROM order_location
)
SELECT
    ol.customer_state,
    ol.orders_by_state,
    ROUND(100.0 * ol.orders_by_state / t.grand_total, 2) AS orders_share
FROM order_location ol
CROSS JOIN total_orders t
ORDER BY ol.orders_by_state DESC
LIMIT 10;
