{% snapshot snp_dim_store %}

{{
    config(
      target_schema='SNAPSHOTS',   
      unique_key='store_code',
      
      strategy='check',
      check_cols=['sales_area', 'location', 'is_tested_region', 'family_range']
    )
}}

select * from {{ ref('stg_dim_store') }}

{% endsnapshot %}