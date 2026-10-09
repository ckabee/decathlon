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
),

-- Création de la ligne par défaut (Dummy Record) pour accueillir les ventes orphelines
dummy_record as (
    select
        -1 as store_code,
        0.00 as sales_area,
        'Unknown' as location_type,
        false as is_tested_region, -- Exclu par défaut des résultats du test A/B
        0 as family_range
)

select * from casted
union all
select * from dummy_record


