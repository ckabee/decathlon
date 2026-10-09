{{
    config(
        materialized = 'table'
    )
}}

with reconciled_data as (
    select * from {{ ref('int_daily_sales_stock_reconciled') }}
),

business_logic_applied as (
    select
        date_day,
        store_code,
        is_test_store,
        product_category,
        transaction_channel_type,
        
        -- 1. Définition du contexte métier (Périodes du test)
        -- Définition dynamique basée sur les variables dbt dans dbt_project.yml
        case
            when date_part('week', date_day) between {{ var('test_dumbbells')['pre_test_start_week'] }} 
                                                 and {{ var('test_dumbbells')['pre_test_end_week'] }} 
                then 'Pre-Test'
            when date_part('week', date_day) between {{ var('test_dumbbells')['test_start_week'] }} 
                                                 and {{ var('test_dumbbells')['test_end_week'] }} 
                then 'Test'
            else 'Out of Scope'
        end as test_period,
        
        -- 2. Reprise des métriques brutes
        nb_transactions,
        total_quantity_sold,
        total_gmv_eur,
        expected_items_count,
        available_items_count,
        stock_availability_rate,
        
        -- Bonus métier : Le panier moyen
        case 
            when nb_transactions > 0 
            then total_gmv_eur / nb_transactions 
            else 0 
        end as average_basket_value_eur

    from reconciled_data
)

select * 
from business_logic_applied
where test_period != 'Out of Scope' -- On nettoie les données inutiles pour le dashboard