{{ config(
    materialized='table',
    cluster_by=["product_group"]
  ) 
}}

with contracts_source as (
    select * from {{ ref('product_customer_source_enriched') }}
),

contracts_enriched as (
    select
        *,
        to_hex(
            sha256(
              concat(
                coalesce(user_id, 'null'),
                coalesce(product_group, 'null'),
                coalesce(cast(acquisition_date as string), '1990-01-01'),
                coalesce(cast(started_at as string), '1990-01-01'),
                coalesce(cast(churned_at as string), cast(current_date() as string))
              ))) as hash_key
    from contracts_source
)

select * from contracts_enriched