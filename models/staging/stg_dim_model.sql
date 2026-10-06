with source as (
    select * from {{ source('raw', 'dim_model') }}
),

casted as (
    select
        try_cast(item_code as integer) as item_code,
        try_cast(model_code as integer) as model_code,
        try_cast(model_name as string) as model_name,
        try_cast(product_weight as double) as product_weight,
        try_cast(product_nature as string) as product_nature,
        try_cast(range_item as integer) as range_item,
        try_cast(picture_url as string) as picture_url
    from source
)

select * from casted 