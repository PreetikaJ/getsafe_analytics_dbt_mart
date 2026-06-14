{{ config(materialized='ephemeral') }}

with bounds as (
    select
        min(started_at) as min_date,
        max(coalesce(churned_at, current_date())) as max_date
    from {{ source('getsafe_curated', 'getsafe_contracts_curated') }}
),

dates as (
    select
      gen_date
    from bounds,
    unnest(generate_date_array(min_date, date_add(max_date, interval 1 day), 
    interval 1 day)) as gen_date

)

select gen_date from dates
order by gen_date