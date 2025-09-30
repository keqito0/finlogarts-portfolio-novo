-- Fonte única de KPIs de cabeçalho
WITH params AS (
  SELECT DATE '2024-01-01' dt_ini, DATE '2024-12-31' dt_fim, NULL regiao
),
base AS (
  SELECT o.order_id, o.customer_id, o.order_date, o.status, c.region,
         p.amount, r.amount AS refund_amount
  FROM `meli-bi-data.TMP.orders_kq` o
  LEFT JOIN `meli-bi-data.TMP.customers_kq` c USING(customer_id)
  LEFT JOIN `meli-bi-data.TMP.payments_kq` p USING(order_id)
  LEFT JOIN `meli-bi-data.TMP.refunds_kq` r USING(order_id)
  WHERE o.order_date BETWEEN (SELECT dt_ini FROM params) AND (SELECT dt_fim FROM params)
    AND ((SELECT regiao FROM params) IS NULL OR c.region = (SELECT regiao FROM params))
),
kpis AS (
  SELECT
    COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM order_date)=2024 THEN customer_id END) AS clientes_ativos_2024,
    SAFE_DIVIDE(SUM(amount), COUNT(DISTINCT order_id)) AS ticket_medio,
    SAFE_DIVIDE(SUM(CASE WHEN status='Entregue' THEN 1 END), COUNT(1)) AS pct_entregue,
    SAFE_DIVIDE(SUM(CASE WHEN status='Cancelado' THEN 1 END), COUNT(1)) AS pct_cancelado
  FROM base
)
SELECT * FROM kpis;
