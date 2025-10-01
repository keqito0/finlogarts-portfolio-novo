
WITH base AS (
  SELECT DISTINCT
    c.customer_id,
    c.region AS region,
    DATE_TRUNC(DATE(o.order_date), YEAR) AS ano_data
  FROM `meli-bi-data.TMP.customers_kq` c
  JOIN `meli-bi-data.TMP.orders_kq` o
    ON c.customer_id = o.customer_id
)
SELECT
  EXTRACT(YEAR FROM ano_data) AS ano,
  ano_data,
  region,
  COUNT(*) AS total_clientes
FROM base
GROUP BY ano, ano_data, region
ORDER BY ano, region;
