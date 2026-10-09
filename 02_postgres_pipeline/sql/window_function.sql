
-- Top 10 states by orders and share of total (window function version)
WITH order_location AS (
    SELECT c.customer_state, COUNT(DISTINCT o.order_id) AS orders_by_state
    FROM raw.orders o
    JOIN raw.customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    orders_by_state,
    ROUND(100.0 * orders_by_state / SUM(orders_by_state) OVER (), 2) AS orders_share
FROM order_location
ORDER BY orders_by_state DESC
LIMIT 10;

-- Share of each item within its order
SELECT
    order_id,
    order_item_id,
    price,
    SUM(price) OVER (PARTITION BY order_id) AS order_total,
    ROUND((100.0 * price / SUM(price) OVER (PARTITION BY order_id))::numeric, 1) AS share_of_order
FROM raw.order_items
ORDER BY order_id, order_item_id
LIMIT 20;

-- Top 3 best-selling products in each category
WITH product_sales AS (
    SELECT 
        p.product_category_name, 
        oi.product_id, 
        COUNT(*) AS items_sold
    FROM raw.order_items oi
    JOIN raw.products p ON oi.product_id = p.product_id
    GROUP BY p.product_category_name, oi.product_id
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY product_category_name ORDER BY items_sold DESC) AS rank_in_category
    FROM product_sales
)
SELECT *
FROM ranked
WHERE rank_in_category <= 3
ORDER BY product_category_name, rank_in_category;


WITH total_by_category AS (SELECT
    p.product_category_name AS category_name,
    COUNT(oi.order_id) AS orders,
    SUM(oi.price) AS revenue
FROM raw.order_items oi
LEFT JOIN raw.products p
ON oi.product_id=p.product_id
GROUP BY category_name
)
SELECT 
    category_name,
    orders,
    revenue,
    ROUND((100*revenue/SUM(revenue) OVER ())::numeric,2)AS total_revenue
FROM total_by_category
ORDER BY revenue DESC
LIMIT 10;

-- Top-selling seller in each state
WITH seller_income AS (
    SELECT
        s.seller_state AS state,
        s.seller_id AS seller,
        SUM(oi.price) AS sales
    FROM raw.sellers s
    JOIN raw.order_items oi ON s.seller_id = oi.seller_id
    GROUP BY s.seller_state, s.seller_id
),
ranked_sellers AS (
    SELECT
        state,
        seller,
        sales,
        ROW_NUMBER() OVER (PARTITION BY state ORDER BY sales DESC) AS rank_in_state
    FROM seller_income
)
SELECT state, seller, sales
FROM ranked_sellers
WHERE rank_in_state = 1
ORDER BY sales DESC;

--- Top-selling category in each state
WITH orders_state AS (
SELECT 
    c.customer_state AS state,
    p.product_category_name AS category_name,
    COUNT(DISTINCT(o.order_id)) AS total_orders 
FROM raw.orders o
JOIN raw.customers c
    ON o.customer_id=c.customer_id
JOIN raw.order_items oi
    ON o.order_id=oi.order_id
JOIN raw.products p
    ON oi.product_id = p.product_id
WHERE p.product_category_name IS NOT null
GROUP BY c.customer_state,p.product_category_name

), rank_category AS (
SELECT 
    state,
    category_name,
    total_orders,
    RANK() OVER (PARTITION BY state ORDER BY total_orders DESC) AS category_rank_state
FROM orders_state
)
SELECT *
FROM rank_category
WHERE category_rank_state=1;




