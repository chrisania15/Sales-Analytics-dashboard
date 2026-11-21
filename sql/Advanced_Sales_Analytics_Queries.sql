USE sales;

/* ============================================================
   TASK 1: MONTHLY REVENUE TREND — 2022
   Revenue is measured using SUM(before_discount), grouped by month.
   ============================================================ */
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(before_discount) AS total_revenue
FROM order_detail
WHERE YEAR(order_date) = 2022
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


/* ============================================================
   TASK 2: SALES BY PAYMENT METHOD
   Shows total sales and total quantity for each payment method.
   ============================================================ */
SELECT
    paydet.payment_method,
    SUM(ordet.before_discount) AS total_sales,
    SUM(ordet.qty_ordered) AS total_quantity
FROM order_detail AS ordet
JOIN payment_detail AS paydet
    ON ordet.payment_id = paydet.id
GROUP BY paydet.payment_method
ORDER BY total_sales DESC;


/* ============================================================
   TASK 3: AVERAGE ORDER VALUE (AOV) — 2022
   AOV = SUM(after_discount) / COUNT(DISTINCT order id), by month.
   ============================================================ */
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(after_discount) / COUNT(DISTINCT id) AS AOV
FROM order_detail
WHERE YEAR(order_date) = 2022
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


/* ============================================================
   TASK 4: REVENUE BEFORE/AFTER DISCOUNT AND DISCOUNT IMPACT
   Discount impact = revenue before discount - revenue after discount.
   ============================================================ */
SELECT
    skudet.category,
    SUM(ordet.before_discount) AS revenue_before_discount,
    SUM(ordet.after_discount) AS revenue_after_discount,
    SUM(ordet.before_discount) - SUM(ordet.after_discount) AS discount_impact
FROM order_detail AS ordet
JOIN sku_detail AS skudet
    ON ordet.sku_id = skudet.id
GROUP BY skudet.category
ORDER BY revenue_before_discount DESC;


/* ============================================================
   TASK 5: TOP 10 PRODUCTS WITH LARGEST SALES DECREASE — 2021 VS 2022
   Sales are measured as SUM(qty_ordered); negative difference means decline.
   ============================================================ */
WITH sales_2021 AS (
    SELECT
        skudet.sku_name,
        SUM(ordet.qty_ordered) AS sales_2021
    FROM order_detail AS ordet
    JOIN sku_detail AS skudet
        ON ordet.sku_id = skudet.id
    WHERE YEAR(ordet.order_date) = 2021
    GROUP BY skudet.sku_name
),
sales_2022 AS (
    SELECT
        skudet.sku_name,
        SUM(ordet.qty_ordered) AS sales_2022
    FROM order_detail AS ordet
    JOIN sku_detail AS skudet
        ON ordet.sku_id = skudet.id
    WHERE YEAR(ordet.order_date) = 2022
    GROUP BY skudet.sku_name
),
all_products AS (
    SELECT sku_name FROM sales_2021
    UNION
    SELECT sku_name FROM sales_2022
)
SELECT
    p.sku_name,
    COALESCE(s21.sales_2021, 0) AS sales_2021,
    COALESCE(s22.sales_2022, 0) AS sales_2022,
    COALESCE(s22.sales_2022, 0) - COALESCE(s21.sales_2021, 0) AS difference
FROM all_products AS p
LEFT JOIN sales_2021 AS s21
    ON p.sku_name = s21.sku_name
LEFT JOIN sales_2022 AS s22
    ON p.sku_name = s22.sku_name
WHERE COALESCE(s22.sales_2022, 0) - COALESCE(s21.sales_2021, 0) < 0
ORDER BY difference ASC
LIMIT 10;


/* ============================================================
   TASK 6A: WEEKEND VS WEEKDAY AVERAGE DAILY SALES BY MONTH — Q4 2022
   Daily sales are summed first, then averaged by month and day type.
   ============================================================ */
WITH daily_sales AS (
    SELECT
        DATE(order_date) AS sales_date,
        SUM(before_discount) AS daily_sales
    FROM order_detail
    WHERE order_date >= '2022-10-01'
      AND order_date < '2023-01-01'
    GROUP BY DATE(order_date)
),
classified_days AS (
    SELECT
        sales_date,
        daily_sales,
        DATE_FORMAT(sales_date, '%Y-%m') AS month,
        CASE
            WHEN DAYOFWEEK(sales_date) IN (1, 7) THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type
    FROM daily_sales
)
SELECT
    month,
    day_type,
    AVG(daily_sales) AS average_daily_sales
FROM classified_days
GROUP BY month, day_type
ORDER BY month, day_type;


/* ============================================================
   TASK 6B: OVERALL WEEKEND VS WEEKDAY AVERAGE DAILY SALES — Q4 2022
   ============================================================ */
WITH daily_sales AS (
    SELECT
        DATE(order_date) AS sales_date,
        SUM(before_discount) AS daily_sales
    FROM order_detail
    WHERE order_date >= '2022-10-01'
      AND order_date < '2023-01-01'
    GROUP BY DATE(order_date)
),
classified_days AS (
    SELECT
        sales_date,
        daily_sales,
        CASE
            WHEN DAYOFWEEK(sales_date) IN (1, 7) THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type
    FROM daily_sales
)
SELECT
    day_type,
    AVG(daily_sales) AS overall_average_daily_sales
FROM classified_days
GROUP BY day_type
ORDER BY day_type;
