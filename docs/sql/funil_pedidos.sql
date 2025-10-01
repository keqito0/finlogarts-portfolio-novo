
-- Funil coerente (Criado → Entregue → Cancelado → Refund) por ANO e REGIÃO
WITH customers AS (
  SELECT DISTINCT customer_id, region AS region
  FROM `meli-bi-data.TMP.customers_kq`
),

-- Criados por ano 
created AS (
  SELECT
    c.region,
    DATE_TRUNC(DATE(o.order_date), YEAR) AS ano_data,
    COUNT(DISTINCT o.order_id) AS criados
  FROM `meli-bi-data.TMP.orders_kq` o
  JOIN customers c USING (customer_id)
  GROUP BY region, ano_data
),

-- Entregues por ano
delivered AS (
  SELECT
    c.region,
    DATE_TRUNC(DATE(s.delivery_date), YEAR) AS ano_data,
    COUNT(DISTINCT s.order_id) AS entregues
  FROM `meli-bi-data.TMP.shipments_kq` s
  JOIN `meli-bi-data.TMP.orders_kq` o ON o.order_id = s.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE s.delivery_date IS NOT NULL
  GROUP BY region, ano_data
),

-- Cancelados por ano (do pedido), EXCLUINDO os que tiveram entrega no mesmo ano
canceled_only AS (
  -- pedidos cancelados no ano X
  SELECT
    c.region,
    DATE_TRUNC(DATE(o.order_date), YEAR) AS ano_data,
    o.order_id
  FROM `meli-bi-data.TMP.orders_kq` o
  JOIN customers c USING (customer_id)
  WHERE o.status = 'Cancelado'
),
canceled_filtered AS (
  SELECT
    co.region,
    co.ano_data,
    COUNT(DISTINCT co.order_id) AS cancelados
  FROM canceled_only co
  LEFT JOIN (
    SELECT  -- entregas por pedido + ano da entrega
      s.order_id,
      DATE_TRUNC(DATE(s.delivery_date), YEAR) AS ano_data
    FROM `meli-bi-data.TMP.shipments_kq` s
    WHERE s.delivery_date IS NOT NULL
  ) d
    ON d.order_id = co.order_id
   AND d.ano_data = co.ano_data        -- exclui se entregou no mesmo ano
  WHERE d.order_id IS NULL
  GROUP BY co.region, co.ano_data
),

-- Refunds no ano Y, somente de pedidos ENTREGUES no mesmo ano Y
refund_of_delivered AS (
  SELECT
    c.region,
    DATE_TRUNC(DATE(r.refund_date), YEAR) AS ano_data
  FROM `meli-bi-data.TMP.refunds_kq` r
  JOIN `meli-bi-data.TMP.shipments_kq` s ON s.order_id = r.order_id
  JOIN `meli-bi-data.TMP.orders_kq` o     ON o.order_id = r.order_id
  JOIN customers c                        ON c.customer_id = o.customer_id
  WHERE r.refund_date IS NOT NULL
    AND s.delivery_date IS NOT NULL
    AND DATE_TRUNC(DATE(r.refund_date), YEAR)
        = DATE_TRUNC(DATE(s.delivery_date), YEAR)  -- refund do que foi entregue no mesmo ano
),
refund_agg AS (
  SELECT
    region,
    ano_data,
    COUNT(DISTINCT CONCAT(region, '|', CAST(ano_data AS STRING), '|', CAST(GENERATE_UUID() AS STRING))) AS refundados
  FROM refund_of_delivered
  GROUP BY region, ano_data
),

-- Junta os totais por ano/região
totais AS (
  SELECT
    COALESCE(cr.region, de.region, ca.region, rf.region) AS region,
    COALESCE(cr.ano_data, de.ano_data, ca.ano_data, rf.ano_data) AS ano_data,
    COALESCE(cr.criados,    0) AS criados,
    COALESCE(de.entregues,  0) AS entregues,
    COALESCE(ca.cancelados, 0) AS cancelados,
    COALESCE(rf.refundados, 0) AS refundados
  FROM created cr
  FULL OUTER JOIN delivered       de ON de.region   = cr.region   AND de.ano_data = cr.ano_data
  FULL OUTER JOIN canceled_filtered ca ON ca.region = COALESCE(cr.region, de.region)
                                      AND ca.ano_data = COALESCE(cr.ano_data, de.ano_data)
  FULL OUTER JOIN refund_agg       rf ON rf.region  = COALESCE(cr.region, de.region, ca.region)
                                      AND rf.ano_data = COALESCE(cr.ano_data, de.ano_data, ca.ano_data)
)

SELECT
  ano_data,
  EXTRACT(YEAR FROM ano_data) AS ano_num,
  region,
  etapa,
  valor
FROM totais,
UNNEST([
  STRUCT('Criado'    AS etapa, criados    AS valor),
  STRUCT('Entregue'  AS etapa, entregues  AS valor),
  STRUCT('Cancelado' AS etapa, cancelados AS valor),
  STRUCT('Refund'    AS etapa, refundados AS valor)
])
ORDER BY ano_data, region, etapa;
