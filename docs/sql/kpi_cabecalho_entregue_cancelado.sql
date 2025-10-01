

WITH base AS (
  SELECT
    c.region AS region,
    o.status
  FROM `meli-bi-data.TMP.orders_kq` o
  LEFT JOIN `meli-bi-data.TMP.customers_kq` c
    ON c.customer_id = o.customer_id
)
SELECT
  region,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(status = 'Entregue'), COUNT(*)), 2) AS pct_entregue,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(status = 'Cancelado'), COUNT(*)), 2) AS pct_cancelado
FROM base
GROUP BY region
ORDER BY region;
