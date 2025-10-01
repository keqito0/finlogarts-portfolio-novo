

WITH itens AS (
  SELECT
    EXTRACT(YEAR FROM o.order_date) AS ano,
    c.region AS region,
    pr.name  AS produto,
    SUM(oi.quantity) AS qtd_itens
  FROM `meli-bi-data.TMP.order_items_kq` oi
  JOIN `meli-bi-data.TMP.orders_kq`      o  ON o.order_id = oi.order_id
  JOIN `meli-bi-data.TMP.products_kq`    pr ON pr.product_id = oi.product_id
  JOIN `meli-bi-data.TMP.customers_kq`   c  ON c.customer_id = o.customer_id
  WHERE o.status = 'Entregue'
  GROUP BY ano, region, produto
),
ranqueado AS (
  SELECT
    ano,
    region,
    produto,
    qtd_itens,
    RANK() OVER (PARTITION BY ano, region ORDER BY qtd_itens DESC) AS rk
  FROM itens
)
SELECT
  ano,
  region,
  produto AS name,
  qtd_itens
FROM ranqueado
WHERE rk <= 10
ORDER BY ano, region, qtd_itens DESC;
