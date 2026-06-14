{{ config(materialized='ephemeral') }}

with monthly_accounting as (
    select
    lower(trim(Party)) AS party,
    parse_date('%Y-%b', Month) AS accounting_month,
    cast(Premium AS float64) AS premium_amount
    from {{ source('getsafe_data_raw', 'accounting_monthly_closing') }} 
)

select * from monthly_accounting