
WITH base AS (
  SELECT
    DATE_TRUNC(DATE(s.delivery_date), YEAR)  AS ano_data,  
    EXTRACT(YEAR FROM s.delivery_date)       AS ano_num,  
    DATE_TRUNC(DATE(s.delivery_date), MONTH) AS mes,
    c.region                                 AS region,
    DATE_DIFF(DATE(s.delivery_date), DATE(s.ship_date), DAY) AS tempo_dias
  FROM `meli-bi-data.TMP.shipments_kq` s
  JOIN `meli-bi-data.TMP.orders_kq`    o USING (order_id)
  JOIN `meli-bi-data.TMP.customers_kq` c ON c.customer_id = o.customer_id
  WHERE s.delivery_date IS NOT NULL
    AND s.ship_date     IS NOT NULL
),
limpa AS (
  SELECT *
  FROM base
  WHERE tempo_dias BETWEEN 0 AND 120
)
SELECT
  ano_data,          
  ano_num,          
  region,
  mes,
  COUNT(*) AS n,
  ROUND(AVG(tempo_dias), 2) AS tempo_medio_dias,
  APPROX_QUANTILES(tempo_dias, 100)[OFFSET(50)] AS mediana_dias,
  APPROX_QUANTILES(tempo_dias, 100)[OFFSET(90)] AS p90_dias,
  ROUND(STDDEV_SAMP(tempo_dias), 2) AS sd_dias,
  ROUND(100 * SAFE_DIVIDE(SUM(CASE WHEN tempo_dias <= 30 THEN 1 ELSE 0 END), COUNT(*)), 1) AS pct_dentro_sla
FROM limpa
GROUP BY ano_data, ano_num, region, mes
ORDER BY ano_data, region, mes;
