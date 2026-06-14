{{ config(materialized='table') }}

select
  date_trunc(date(created_at), month) as month,
  count(distinct date(created_at)) as distinct_days,
  min(date(created_at)) as min_date,
  max(date(created_at)) as max_date
from {{ ref('getsafe_transaction_data_enriched') }}
group by 1
order by 1