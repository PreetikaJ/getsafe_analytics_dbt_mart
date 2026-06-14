{{ config(
  materialized='incremental',
  incremental_strategy='insert_overwrite',
  partition_by={
    'field': 'gen_date',
    'data_type': 'date',
    'granularity': 'day'
  },
  cluster_by=['product_group', 'user_id'],
  on_schema_change='sync_all_columns'
) }}

with contracts as (
    select *
    from {{ source('getsafe_curated', 'getsafe_contracts_curated') }}
),

dates as (
    select gen_date
    from {{ ref('create_date_spine') }}
    {% if is_incremental() %}
      where gen_date >= date_sub(current_date(), interval 90 day)
    {% endif %}
),

data_joined as (
    select
        d.gen_date,
        c.hash_key,
        c.user_id,
        c.product_group,
        c.acquisition_date,
        c.started_at,
        c.churned_at,
        c.monthly_premium
    from contracts c
    inner join dates d
      on d.gen_date >= c.started_at
     and (c.churned_at is null or d.gen_date <= c.churned_at)
),

final as (
    select
        to_hex(sha256(concat(hash_key, cast(gen_date as string)))) as daily_contract_hash_key,
        gen_date,
        hash_key,
        user_id,
        product_group,
        acquisition_date,
        started_at,
        churned_at,
        monthly_premium,
        1 as active_customers,
        safe_divide(monthly_premium,
            extract(day from last_day(gen_date))
        ) as active_daily_premium,
        case
            when gen_date = started_at then monthly_premium
            when extract(day from gen_date) = 1 then monthly_premium
            else 0
         end as active_monthly_premium
    from data_joined
)

select 
    daily_contract_hash_key,
    gen_date,
    hash_key,
    user_id,
    product_group,
    acquisition_date,
    started_at,
    churned_at,
    sum(active_monthly_premium) as active_monthly_premium,
    sum(active_customers) as active_customers,
    sum(active_daily_premium) as active_daily_premium,
    count(*) as row_count
from final
group by all