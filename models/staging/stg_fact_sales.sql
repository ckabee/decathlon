with source as (
    select * from {{ source('raw', 'fact_sales') }}
),

casted as (
    select
        try_cast(transaction_id as string) as transaction_id,
        try_cast(transaction_date as date) as transaction_date,
        try_cast(store_code as integer) as store_code,
        try_cast(transaction_channel_type as string) as transaction_channel_type,
        try_cast(item_code as integer) as item_code,
        try_cast(item_operation_type as string) as item_operation_type,
        try_cast(quantity as integer) as quantity,
        try_cast(gmv as decimal(32,6)) as gmv
    from source
)

select * from casted 