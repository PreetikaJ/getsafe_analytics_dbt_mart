{{ config(
    materialized='table',
    cluster_by=["party"]
  ) 
}}

with accounting as (
    select
        party,
        accounting_month,
        premium_amount as accounting_premium
    from {{ ref('getsafe_accounting_monthly_data') }}
),

finance as (
    select
        party,
        finance_month,
        gross_premium_amount,
        premium_refunded,
        premium_processed,
        net_premium_amount as finance_premium
    from {{ ref('getsafe_premium_data') }}
),

accounting_finance_enriched as (
    select
        coalesce(a.party, f.party) as party,
        coalesce(a.accounting_month, f.finance_month) as month,
        coalesce(a.accounting_premium, 0) as accounting_premium,
        coalesce(f.finance_premium, 0) as finance_premium,
        coalesce(f.gross_premium_amount, 0) as gross_premium_amount,
        coalesce(f.premium_refunded, 0) as premium_refunded,
        coalesce(f.premium_processed, 0) as premium_processed,
        round(coalesce(f.finance_premium, 0) - coalesce(a.accounting_premium, 0), 2) as variance,
        round((coalesce(f.finance_premium, 0) - coalesce(a.accounting_premium, 0)) / nullif(a.accounting_premium, 0), 6)    
        as percentage_variance
    from accounting a
    full outer join finance f
        on a.party = f.party
       and a.accounting_month = f.finance_month
),

final as (
    select
        party,
        month,
        accounting_premium,
        finance_premium,
        gross_premium_amount,
        premium_refunded,
        premium_processed,
        variance,
        percentage_variance,
        case
            when accounting_premium = 0 and finance_premium <> 0 then 'missing_in_accounting'
            when accounting_premium <> 0 and finance_premium = 0 then 'missing_in_finance'
            when finance_premium < accounting_premium then 'finance_lower_than_accounting'
            when finance_premium > accounting_premium then 'finance_higher_than_accounting'
            when finance_premium = accounting_premium then 'finance_equal_to_accounting'
            else 'unknown'
        end as discrepancy_outcome
    from accounting_finance_enriched
)

select * from final