with source as (
    select * from {{ source('raw', 'dim_store') }}
),

casted as (
    select
        try_cast(store_code as integer) as store_code,
        try_cast(sales_area as integer) as sales_area,
        try_cast(location as string) as location,
        try_cast(is_tested_region as boolean) as is_tested_region,
        try_cast(family_range as integer) as family_range
    from source
)

select * from casted 
