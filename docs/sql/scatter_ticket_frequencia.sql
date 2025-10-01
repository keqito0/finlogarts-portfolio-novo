WITH pedidos_por_cliente AS (
  SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS qtd_pedidos,
    ROUND(SUM(oi.price * oi.quantity), 2) AS receita_total,
    ROUND(SUM(oi.price * oi.quantity) / COUNT(DISTINCT o.order_id), 2) AS ticket_medio
  FROM `meli-bi-data.TMP.orders_kq` o
  JOIN `meli-bi-data.TMP.order_items_kq` oi ON o.order_id = oi.order_id
  WHERE o.status = 'Entregue'
    AND o.order_date BETWEEN '2024-01-01' AND '2024-12-31'
  GROUP BY o.customer_id
)
SELECT
  c.customer_id,
  c.name AS customer_name,
  c.region,
  qtd_pedidos AS frequencia_compra,
  ticket_medio,
  receita_total
FROM pedidos_por_cliente pc
JOIN `meli-bi-data.TMP.customers_kq` c  ON pc.customer_id = c.customer_id;

