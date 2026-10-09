{{
    config(
        materialized = 'table'
    )
}}

with sales as (
    select * from {{ ref('int_daily_sales') }}
),

stock as (
    select * from {{ ref('int_daily_stock_availability') }}
),

-- Le FULL OUTER JOIN est indispensable car on peut avoir du stock sans vente, 
-- et exceptionnellement des ventes sans stock (ex: commande en ligne)
reconciled as (
    select
        coalesce(sl.transaction_date, st.stock_date) as date_day,
        coalesce(sl.store_code, st.store_code) as store_code,
        coalesce(sl.is_tested_region, st.is_test_store) as is_test_store,
        coalesce(sl.product_category, st.product_category) as product_category,
        coalesce(sl.transaction_channel_type, 'unknown') as transaction_channel_type,
        
        -- Métriques de ventes (remplacées par 0 s'il n'y a pas eu de vente ce jour-là)
        coalesce(sl.nb_transactions, 0) as nb_transactions,
        coalesce(sl.total_net_quantity, 0) as total_quantity_sold,
        coalesce(sl.total_net_gmv, 0) as total_gmv_eur,
        
        -- Métriques de stock
        coalesce(st.expected_items_count, 0) as expected_items_count,
        coalesce(st.available_items_count, 0) as available_items_count,
        
        -- Taux de disponibilité calculé à la volée 
        case 
            when st.expected_items_count > 0 
            -- Taux plafonné à 100% 
            then least( (st.available_items_count * 1.0) / st.expected_items_count, 1.0 ) 
        end as stock_availability_rate

    from sales as sl
    full outer join stock as st
        on sl.transaction_date = st.stock_date
        and sl.store_code = st.store_code
        and sl.product_category = st.product_category
)

select * from reconciled