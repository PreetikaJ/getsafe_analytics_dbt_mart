{{ config( materialized='ephemeral' ) }}

with transaction_enriched as (
    select distinct
        transaction_id,
        parse_timestamp('%m/%d/%Y %H:%M:%S', created_at) as created_at,
        cast(premium_amount as float64) as premium_amount,
        lower(trim(premium_currency)) as premium_currency,
        lower(trim(charged_party)) as party,
        lower(trim(status)) as premium_status
    from {{ source('getsafe_data_raw', 'getsafe_transaction_data_raw') }}
)

select * from transaction_enriched