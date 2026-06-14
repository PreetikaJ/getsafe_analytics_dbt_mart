{{ config(materialized='ephemeral') }}

with product_customer_source as (
    select 
        cast(`ACQUISITION DATE` as timestamp) as acquisition_timestamp,
        date(cast(`ACQUISITION DATE` as timestamp)) as acquisition_date,
        date(cast(`STARTED AT` as timestamp)) as started_at,
        date(cast(`CHURNED AT` as timestamp)) as churned_at,
        cast(`USER ID` as string) as user_id,
        cast(`PREMIUM` as float64) as monthly_premium,
        lower(trim(cast(`PRODUCT GROUP` as string))) as product_group
    from {{ source('getsafe_data_raw', 'sample_products_customers') }}
)

select * from product_customer_source