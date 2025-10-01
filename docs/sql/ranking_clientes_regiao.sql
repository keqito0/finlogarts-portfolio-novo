


WITH pedidos AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.status,
    EXTRACT(YEAR FROM o.order_date) AS ano
  FROM `meli-bi-data.TMP.orders_kq` o
),

pagamentos AS (
  SELECT
    o.order_id,
    EXTRACT(YEAR FROM o.order_date) AS ano,
    SUM(p.amount) AS total_pago
  FROM `meli-bi-data.TMP.orders_kq` o
  JOIN `meli-bi-data.TMP.payments_kq` p USING (order_id)
  GROUP BY o.order_id, ano
),

reembolsos AS (
  SELECT
    o.order_id,
    EXTRACT(YEAR FROM o.order_date) AS ano,
    SUM(r.amount) AS total_refund
  FROM `meli-bi-data.TMP.orders_kq` o
  JOIN `meli-bi-data.TMP.refunds_kq` r USING (order_id)
  GROUP BY o.order_id, ano
),

base_pedidos AS (
  SELECT
    p.order_id,
    p.customer_id,
    p.ano,
    p.status,
    COALESCE(pg.total_pago, 0)  AS total_pago,
    COALESCE(rb.total_refund, 0) AS total_refund,
    COALESCE(pg.total_pago, 0) - COALESCE(rb.total_refund, 0) AS receita_pedido
  FROM pedidos p
  LEFT JOIN pagamentos pg
    ON pg.order_id = p.order_id AND pg.ano = p.ano
  LEFT JOIN reembolsos rb
    ON rb.order_id = p.order_id AND rb.ano = p.ano
  WHERE p.status = 'Entregue'
),

receita_por_cliente AS (
  SELECT
    bp.ano,
    bp.customer_id,
    c.name   AS customer_name,
    c.region AS region,
    ROUND(SUM(bp.receita_pedido), 2) AS receita_liquida_cliente
  FROM base_pedidos bp
  JOIN `meli-bi-data.TMP.customers_kq` c
    ON bp.customer_id = c.customer_id
  GROUP BY bp.ano, bp.customer_id, customer_name, region
),

ranqueado AS (
  SELECT
    ano,
    region,
    customer_id,
    customer_name,
    receita_liquida_cliente,
    RANK() OVER (PARTITION BY ano, region ORDER BY receita_liquida_cliente DESC) AS rk
  FROM receita_por_cliente
)

SELECT
  ano,
  region,
  rk AS ranking_regional,
  customer_id,
  customer_name,
  receita_liquida_cliente
FROM ranqueado
WHERE rk <= 5
ORDER BY ano, region, ranking_regional;
