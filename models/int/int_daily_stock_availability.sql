{{
    config(
        materialized = 'table',
        liquid_clustered_by = ['stock_date', 'store_code']
    )
}}

with stock as (
    select * from {{ ref('stg_fact_stock') }}
),

stores as (
    select * from {{ ref('stg_dim_store') }}
),

models as (
    select * from {{ ref('stg_dim_model') }}
),

enriched_stock as (
    select
        sk.stock_date,
        sk.store_code,
        st.is_tested_region as is_test_store,
        
        case
            when upper(m.model_name) like '%KIT%10KG%' then 'Kit 10kg (Target)'
            when upper(m.model_name) like '%20KG%' and upper(m.model_name) like '%KIT%' then 'Kit 20kg (Alternative)'
            else 'Unit Weights & Others'
        end as product_category,
        
        sk.is_tracked,            -- Correspond au top_suivi
        sk.is_available_in_stock  -- Correspond au top_available_stock
        
    from stock as sk
    inner join stores as st on sk.store_code = st.store_code
    inner join models as m on sk.item_code = m.item_code
),

aggregated_daily_stock as (
    select
        stock_date,
        store_code,
        is_test_store,
        product_category,
        
        -- Comptage des articles théoriquement attendus dans le magasin (L'assortiment)
        sum(case when is_tracked then 1 else 0 end) as expected_items_count,
        
        -- Comptage des articles physiquement disponibles pour le client (La réalité)
        sum(case when is_available_in_stock then 1 else 0 end) as available_items_count
        
    from enriched_stock
    group by 1, 2, 3, 4
)

select
    {{ dbt_utils.generate_surrogate_key(['stock_date', 'store_code', 'product_category']) }} as daily_stock_id,
    *
from aggregated_daily_stock