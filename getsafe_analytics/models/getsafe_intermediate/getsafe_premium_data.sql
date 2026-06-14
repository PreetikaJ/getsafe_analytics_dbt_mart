{{ config(materialized='ephemeral') }}

with premium_data as (
    select
        finance_month,
        party,
        premium_amount,
        premium_processed,
        premium_refunded,
        premium_amount_normalized
    from {{ source('getsafe_curated', 'getsafe_transaction_data_curated') }}
    where is_premium_relevant = true
),

premium_final as (
    select
        party,
        finance_month,
        round(sum(premium_processed), 2) as premium_processed,
        round(sum(premium_refunded), 2) as premium_refunded,
        round(sum(premium_amount), 2) as gross_premium_amount,
        round(sum(premium_amount_normalized), 2) as net_premium_amount
    from premium_data
    group by party, finance_month
)

select * from premium_final