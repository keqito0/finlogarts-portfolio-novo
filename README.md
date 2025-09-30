# FinLogArts — BI & Analytics (BigQuery + Looker)

Projeto de portfólio com dados fictícios (`meli-bi-data.TMP.*`) para demonstrar **SQL (BigQuery)**, **modelagem de métricas** e **dashboard (Looker Studio)**.

## 🔗 Links
- **Dashboard (Looker Studio):** https://lookerstudio.google.com/u/0/reporting/2ef16139-c9fe-48fa-9a90-f62e3603fcd7/page/ZBcYF  (público)
- **One-pager (PDF):** ./docs/onepager.pdf

##  Como reproduzir
1. Abra o **BigQuery (Standard SQL)**.
2. Em `/sql`, ajuste os parâmetros de período no topo dos arquivos (CTE `params` com `dt_ini` e `dt_fim`; use `regiao` se quiser filtrar).
3. Execute na ordem:
   - `01_base_quality_checks.sql`  → checagens de qualidade (datas negativas, nulos, duplicidades).
   - `02_views_kpis.sql`           → **fonte única** dos KPIs de cabeçalho.
   - `03_views_funil.sql`          → funil **Criado→Enviado→Entregue→Cancelado→Refund** por ano/região.
   - `04_views_sla_logistica.sql`  → SLA mensal (cap 0–120 dias) + p50/p90.
4. Conecte as views/queries no **Looker Studio** e gere os 5 visuais.
5. Exporte os prints para `./docs/prints/` e o one-pager para `./docs/onepager.pdf`.

##  Visuais do painel (5)
- `clientes_ativos.png` — Clientes ativos por ano.
- `faturamento_mensal_2024.png` — Faturamento mensal (2024).
- `ticket_regiao.png` — Ticket médio por região.
- `funil_pedidos.png` — Funil de pedidos.
- `sla_mensal.png` — Tempo médio de entrega (mês a mês).

##  Checklist de qualidade (usado no projeto)
- Datas negativas (envio < pedido) → investigar.
- Nulos críticos (order_id, customer_id, datas) → corrigir/filtrar.
- Duplicidades de pedido → garantir unicidade.
- Cap de tempos **0–120 dias** para SLA; refunds atrelados ao **mesmo ano** da entrega.

##  Dicionário (resumo do schema)
- `orders_kq(order_id, customer_id, order_date, status)`
- `shipments_kq(order_id, ship_date)`
- `deliveries_kq(order_id, delivery_date)`
- `payments_kq(order_id, payment_date, amount)`
- `refunds_kq(order_id, refund_date, amount)`
- `customers_kq(customer_id, region)`

##  Decisões de modelagem (por quê assim?)
- **Refunds** só contam para pedidos **Entregues** e no **mesmo ano** da entrega → evita dupla contagem.
- **SLA** com cap **0–120 dias** → remove outliers operacionais sem distorcer a média.
- **Fonte única de KPIs** (02_views_kpis.sql) → reduz inconsistências entre visuais.
- **Filtros padrão**: `ano` e `regiao` aplicados na camada SQL → painéis consistentes.

<p align="center">
  <img src="./docs/prints/clientes_ativos.png" width="45%"/>
  <img src="./docs/prints/faturamento_mensal_2024.png" width="45%"/><br/>
  <img src="./docs/prints/ticket_regiao.png" width="45%"/>
  <img src="./docs/prints/funil_pedidos.png" width="45%"/><br/>
  <img src="./docs/prints/sla_mensal.png" width="90%"/>
</p>


