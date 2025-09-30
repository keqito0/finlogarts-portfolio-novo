-- Funil Criado→Enviado→Entregue→Cancelado→Refund por ano/região
WITH params AS (
  SELECT DATE '2024-01-01' dt_ini, DATE '2024-12-31' dt_fim, NULL regiao
),
f AS (
  SELECT
    EXTRACT(YEAR FROM o.order_date) AS ano,
    c.region,
    COUNT(*) AS criados,
    COUNTIF(s.ship_date IS NOT NULL) AS enviados,
    COUNTIF(o.status='Entregue') AS entregues,
    COUNTIF(o.status='Cancelado') AS cancelados,
    COUNTIF(r.amount IS NOT NULL AND o.status='Entregue') AS refunds
  FROM `meli-bi-data.TMP.orders_kq` o
  LEFT JOIN `meli-bi-data.TMP.customers_kq` c USING(customer_id)
  LEFT JOIN `meli-bi-data.TMP.shipments_kq` s USING(order_id)
  LEFT JOIN `meli-bi-data.TMP.refunds_kq` r USING(order_id)
  WHERE o.order_date BETWEEN (SELECT dt_ini FROM params) AND (SELECT dt_fim FROM params)
    AND ((SELECT regiao FROM params) IS NULL OR c.region = (SELECT regiao FROM params))
  GROUP BY ano, region
)
SELECT * FROM f ORDER BY ano, region;
