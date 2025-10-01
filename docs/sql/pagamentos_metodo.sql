

WITH base AS (
  SELECT
    DATE_TRUNC(DATE(p.payment_date), YEAR)  AS ano_data,   
    EXTRACT(YEAR FROM p.payment_date)       AS ano_num,    
    DATE_TRUNC(DATE(p.payment_date), MONTH) AS mes,        
    c.region                                AS region,
    COALESCE(p.method, 'Sem método')        AS method,
    p.amount
  FROM `meli-bi-data.TMP.payments_kq` p
  JOIN `meli-bi-data.TMP.orders_kq`   o USING (order_id)
  JOIN `meli-bi-data.TMP.customers_kq` c ON c.customer_id = o.customer_id
  WHERE p.payment_date IS NOT NULL
)
SELECT
  ano_data,
  ano_num,
  region,
  method,
  mes,
  ROUND(SUM(amount), 2) AS total
FROM base
GROUP BY ano_data, ano_num, region, method, mes
ORDER BY ano_data, region, mes, method;
