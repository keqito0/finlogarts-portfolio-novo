

WITH customers AS (
  SELECT DISTINCT
    customer_id,
    region AS region
  FROM `meli-bi-data.TMP.customers_kq`
),

first_order AS (
  SELECT
    o.customer_id,
    c.region,
    DATE_TRUNC(DATE(MIN(o.order_date)), MONTH) AS cohort_month
  FROM `meli-bi-data.TMP.orders_kq` o
  JOIN customers c USING (customer_id)
  WHERE o.status = 'Entregue'
  GROUP BY o.customer_id, c.region
),

orders_clean AS (
  SELECT
    o.customer_id,
    c.region,
    DATE_TRUNC(DATE(o.order_date), MONTH) AS order_month
  FROM `meli-bi-data.TMP.orders_kq` o
  JOIN customers c USING (customer_id)
  WHERE o.status = 'Entregue'
),

cohort_data AS (
  SELECT
    fo.customer_id,
    fo.region,
    fo.cohort_month,
    oc.order_month,
    DATE_DIFF(oc.order_month, fo.cohort_month, MONTH) AS month_index
  FROM first_order fo
  JOIN orders_clean oc USING (customer_id, region)
),

cohort_by_year AS (
  SELECT
    region,
    EXTRACT(YEAR FROM cohort_month) AS ano,
    COUNT(DISTINCT customer_id) AS clientes_cohort
  FROM cohort_data
  GROUP BY region, ano
),

recompra_same_year AS (
  SELECT
    region,
    EXTRACT(YEAR FROM cohort_month) AS ano,
    COUNT(DISTINCT customer_id) AS clientes_recompra
  FROM cohort_data
  WHERE EXTRACT(YEAR FROM order_month) = EXTRACT(YEAR FROM cohort_month)
    AND month_index > 0
  GROUP BY region, ano
)

SELECT
  COALESCE(c.region, r.region) AS region,
  COALESCE(c.ano, r.ano)       AS ano,
  c.clientes_cohort            AS clientes_cohort,
  r.clientes_recompra          AS clientes_recompra,
  ROUND(100 * SAFE_DIVIDE(r.clientes_recompra, c.clientes_cohort), 2) AS taxa_recompra
FROM cohort_by_year c
FULL OUTER JOIN recompra_same_year r
  ON c.region = r.region AND c.ano = r.ano
ORDER BY ano, region;
