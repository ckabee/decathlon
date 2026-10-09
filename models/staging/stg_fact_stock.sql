with source as (
    select * from {{ source('raw', 'fact_stock') }}
),

casted as (
    select
        try_cast(stock_date as date) as stock_date,
        try_cast(store_code as integer) as store_code,
        try_cast(item_code as integer) as item_code,
        try_cast(top_suivi as boolean) as is_tracked,
        try_cast(top_available_stock as boolean) as is_available_in_stock
    from source
)

select * from casted 