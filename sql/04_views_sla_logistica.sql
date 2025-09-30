-- SLA (dias) com cap 0–120, série mensal
WITH params AS (
  SELECT DATE '2024-01-01' dt_ini, DATE '2024-12-31' dt_fim
),
t AS (
  SELECT
    DATE_TRUNC(o.order_date, MONTH) AS mes,
    DATE_DIFF(d.delivery_date, s.ship_date, DAY) AS dias
  FROM `meli-bi-data.TMP.orders_kq` o
  JOIN `meli-bi-data.TMP.shipments_kq` s USING(order_id)
  JOIN `meli-bi-data.TMP.deliveries_kq` d USING(order_id)
  WHERE o.status='Entregue'
    AND o.order_date BETWEEN (SELECT dt_ini FROM params) AND (SELECT dt_fim FROM params)
),
cap AS (
  SELECT mes, CASE WHEN dias < 0 THEN 0 WHEN dias > 120 THEN 120 ELSE dias END AS dias_cap
  FROM t
)
SELECT mes,
       ROUND(AVG(dias_cap),2) AS tempo_medio_dias,
       APPROX_QUANTILES(dias_cap, 100)[OFFSET(50)] AS p50,
       APPROX_QUANTILES(dias_cap, 100)[OFFSET(90)] AS p90
FROM cap
GROUP BY mes
ORDER BY mes;
