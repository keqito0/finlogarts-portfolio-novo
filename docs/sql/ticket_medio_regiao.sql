
WITH base AS (
  SELECT
    o.order_id,
    c.region,
    SUM(oi.price * oi.quantity) AS total_pedido
  FROM `meli-bi-data.TMP.order_items_kq` oi
  LEFT JOIN `meli-bi-data.TMP.orders_kq` o
    ON oi.order_id = o.order_id
  LEFT JOIN `meli-bi-data.TMP.customers_kq` c
    ON o.customer_id = c.customer_id
  GROUP BY o.order_id, c.region
)
SELECT
  region,
  ROUND(AVG(total_pedido)) AS ticket_medio
FROM base
GROUP BY region
ORDER BY ticket_medio DESC;
