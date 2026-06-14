{{ config(
    materialized='table',
    cluster_by=["transaction_id", "premium_status"]
  ) 
}}

with enriched as (
    select
        transaction_id,
        created_at,
        date_trunc(date(created_at), month) as finance_month,
        premium_amount,
        premium_currency,
        party,
        premium_status,
        case
            when premium_status in ('processed', 'refunded') then true
            else false
        end as is_premium_relevant,
        case when premium_status = 'processed' then premium_amount end as premium_processed,
        case when premium_status = 'refunded'  then premium_amount end as premium_refunded,
        case
            when premium_status = 'processed' then premium_amount
            when premium_status = 'refunded'  then -premium_amount
            else 0
        end as premium_amount_normalized,
        case
            when premium_status = 'processed' then 'premium_charge'
            when premium_status = 'refunded'  then 'premium_refund'
            else 'other'
        end as transaction_type
    from {{ ref('getsafe_transaction_data_enriched') }}
)

select
    transaction_id,
    created_at,
    finance_month,
    premium_amount,
    premium_processed,
    premium_refunded,
    premium_amount_normalized,
    premium_currency,
    party,
    premium_status,
    is_premium_relevant,
    transaction_type
from enriched