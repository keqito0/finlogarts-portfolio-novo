
WITH params AS (
  SELECT 30 AS sla_dias  
),

deliv AS (
  SELECT
    DATE_TRUNC(DATE(s.delivery_date), YEAR) AS ano_data,        
    EXTRACT(YEAR FROM s.delivery_date)       AS ano_num,       
    c.region                                 AS region,
    CAST(s.carrier_id AS STRING)             AS transportadora,
    s.order_id,
    s.ship_date,
    s.delivery_date,
    DATE_DIFF(s.delivery_date, s.ship_date, DAY) AS tempo_dias
  FROM `meli-bi-data.TMP.shipments_kq` s
  JOIN `meli-bi-data.TMP.orders_kq`    o USING (order_id)
  JOIN `meli-bi-data.TMP.customers_kq` c ON c.customer_id = o.customer_id
  WHERE s.delivery_date IS NOT NULL
    AND s.ship_date     IS NOT NULL
    AND DATE_DIFF(s.delivery_date, s.ship_date, DAY) BETWEEN 0 AND 120
),

agg AS (
  SELECT
    ano_data,
    ano_num,
    region,
    transportadora,
    COUNT(DISTINCT order_id) AS entregas,
    ROUND(AVG(tempo_dias), 2) AS sla_medio_dias,
    ROUND(
      100 * SAFE_DIVIDE(
        SUM(CASE WHEN tempo_dias > (SELECT sla_dias FROM params) THEN 1 ELSE 0 END),
        COUNT(*)
      ), 2
    ) AS pct_atraso
  FROM deliv
  GROUP BY ano_data, ano_num, region, transportadora
),

-- Refunds no MESMO ANO da entrega (coerência)
refunds_por_transportadora AS (
  SELECT
    d.ano_data,
    d.ano_num,
    d.region,
    d.transportadora,
    COUNT(DISTINCT r.order_id) AS qtd_refund
  FROM deliv d
  JOIN `meli-bi-data.TMP.refunds_kq` r USING (order_id)
  WHERE DATE_TRUNC(DATE(r.refund_date), YEAR) = d.ano_data
  GROUP BY d.ano_data, d.ano_num, d.region, d.transportadora
)

SELECT
  a.ano_data,
  a.ano_num,
  a.region,
  a.transportadora,
  a.sla_medio_dias,
  a.pct_atraso,
  ROUND(100 * SAFE_DIVIDE(COALESCE(r.qtd_refund, 0), a.entregas), 2) AS pct_refund
FROM agg a
LEFT JOIN refunds_por_transportadora r
  ON r.ano_data = a.ano_data
 AND r.region   = a.region
 AND r.transportadora = a.transportadora
ORDER BY ano_data, region, sla_medio_dias ASC;
