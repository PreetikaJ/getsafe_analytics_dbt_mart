{{ config(materialized='table') }}

with finance_transaction as (
    select
        party,
        finance_month as month,
        round(sum(case when premium_status in ('processed','process') then premium_amount end),2) as finance_premium_processed,
        round(sum(case when premium_status = 'refunded' then premium_amount end),2) as refunds,
    from {{ source('getsafe_curated', 'getsafe_transaction_data_curated') }}
    group by 1, 2
),

accounting_transaction as (
    select
        party,
        accounting_month as month,
        round(sum(premium_amount),2) as accounting_premium
    from {{ ref('getsafe_accounting_monthly_data') }}
    group by 1, 2
),

transaction_joined as (
    select
        coalesce(a.party, f.party) as party,
        coalesce(a.month, f.month) as month,
        a.accounting_premium,
        f.refunds,
        f.finance_premium_processed,
        case
            when f.finance_premium_processed < a.accounting_premium then 'finance_lower_than_accounting'
            when f.finance_premium_processed > a.accounting_premium then 'finance_higher_than_accounting'
            when f.finance_premium_processed = a.accounting_premium then 'finance_equal_to_accounting'
            else 'unknown'
        end as discrepancy_outcome
    from accounting_transaction as a
    left join finance_transaction as f
    on a.party = f.party
    and a.month = f.month
)

select * from transaction_joined order by 1, 2