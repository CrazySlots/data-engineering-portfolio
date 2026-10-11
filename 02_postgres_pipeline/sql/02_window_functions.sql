
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


-- Year-over-year growth: each month of 2018 vs the same month of 2017
-- Period with complete data: Jan 2017 - Aug 2018
WITH sales_by_year_month AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp::timestamp)::date AS month,
    COUNT(*) AS orders
    FROM raw.orders
    WHERE order_purchase_timestamp::timestamp >= '2017-01-01'
      AND order_purchase_timestamp::timestamp <  '2018-09-01'
    GROUP BY month
), previous_table AS (
SELECT
    month,
    orders,
    LAG(orders,12) OVER (ORDER BY MONTH) AS previous_year_sales
FROM sales_by_year_month
)
SELECT
    month,
    orders,
    previous_year_sales,
    ROUND(100.0 * (orders - previous_year_sales) / previous_year_sales, 1) AS year_growth_pct
FROM previous_table
WHERE month >= '2018-01-01'
ORDER BY month;


-- Cumulative orders by month for the top 3 states (SP, RJ, MG)
WITH monthly_sales_state AS (
    SELECT
        c.customer_state AS state,
        DATE_TRUNC('month',o.order_purchase_timestamp::timestamp)::date AS month,
        o.order_id AS order_id
    FROM raw.orders O
    JOIN raw.customers C
    ON o.customer_id = c.customer_id
    WHERE c.customer_state IN ('SP', 'RJ', 'MG')
      AND o.order_purchase_timestamp::timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp::timestamp <  '2018-09-01'
    ), sales_per_state AS (
        SELECT
            state,
            month,
            COUNT(order_id) AS orders_total
        FROM monthly_sales_state
        GROUP BY state, month
    )
SELECT
        state,
        month,
        orders_total,
        SUM(orders_total) OVER (PARTITION BY state ORDER BY month) AS cumulative_orders
FROM sales_per_state
ORDER BY state,MONTH;


-- Days between each customer's first and second purchase
-- customer_unique_id identifies the person (customer_id changes on every order)
WITH unique_customers_orders AS (
    SELECT
        c.customer_unique_id AS unique_id,
        o.order_id AS order_id,
        o.order_purchase_timestamp::date AS purchase_day

    FROM raw.orders o
    JOIN raw.customers c
    ON o.customer_id = c.customer_id
), days_diff_between_purchase AS (
SELECT
    unique_id,
    order_id,
    purchase_day - (LAG(purchase_day) OVER (PARTITION BY unique_id ORDER BY purchase_day)) AS dates_between_purchase,
    ROW_NUMBER() OVER (PARTITION BY unique_id ORDER BY purchase_day) AS order_number
FROM unique_customers_orders
)
SELECT *
FROM days_diff_between_purchase
WHERE order_number = 2
ORDER BY unique_id;

