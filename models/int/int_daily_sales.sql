{{
    config(
        materialized = 'table',
        liquid_clustered_by = ['transaction_date', 'store_code', 'product_category']
    )
}}

with sales as (
    select * from {{ ref('stg_fact_sales') }}
),

-- 1. Lecture du Snapshot brut
raw_stores_scd2 as (
    select * from {{ ref('snp_dim_store') }}
),

-- 2. Le fix de l'historique (Backdating)
stores_scd2 as (
    select
        *,
        -- Si c'est la toute première itération du magasin, on antidate la validité à 1900
        -- Cela permet d'englober toutes les ventes du passé (2023)
        case
            when row_number() over (partition by store_code order by dbt_valid_from asc) = 1 
            then '1900-01-01'::timestamp
            else dbt_valid_from
        end as effective_valid_from
    from raw_stores_scd2
),

models as (
    select * from {{ ref('stg_dim_model') }}
),

enriched_sales as (
    select
        s.transaction_id,
        s.transaction_date,
        coalesce(st.store_code, -1) as store_code,
        coalesce(st.is_tested_region, false) as is_tested_region,
        s.transaction_channel_type, -- 'offline' or 'online'
        
        case
            when upper(m.model_name) like '%KIT%10KG%' then 'Kit 10kg (Target)'
            when upper(m.model_name) like '%20KG%' and upper(m.model_name) like '%KIT%' then 'Kit 20kg (Alternative)'
            else 'Unit Weights & Others'
        end as product_category,
        
        {{ calculate_net_value('s.item_operation_type', 's.quantity') }} as net_quantity,
        {{ calculate_net_value('s.item_operation_type', 's.gmv') }} as net_gmv

    from sales as s
    left join stores_scd2 as st 
        on s.store_code = st.store_code
        and s.transaction_date >= date(st.effective_valid_from)
        and s.transaction_date < coalesce(date(st.dbt_valid_to), '2099-12-31'::date)
    inner join models as m on s.item_code = m.item_code
),

aggregated_daily as (
    select
        transaction_date,
        store_code,
        is_tested_region,
        transaction_channel_type,
        product_category,
        
        count(distinct transaction_id) as nb_transactions,
        sum(net_quantity) as total_net_quantity,
        sum(net_gmv) as total_net_gmv
    from enriched_sales
    group by 1, 2, 3, 4, 5
)

select
    {{ dbt_utils.generate_surrogate_key(['transaction_date', 'store_code', 'transaction_channel_type', 'product_category']) }} as daily_sales_id,
    *
from aggregated_daily