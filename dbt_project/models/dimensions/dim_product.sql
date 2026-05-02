with source as (

    select *
    from {{ source('raw', 'product_dim') }}

),

cleaned as (

    select
        product_id,
        category_id,

        coalesce(nullif(trim(category_code), ''), 'unknown') as category_code,
        coalesce(nullif(trim(brand), ''), 'unknown') as brand,

        source_system,
        loaded_at

    from source

    where product_id is not null

),

final as (

    select
        product_id,
        category_id,
        category_code,
        brand,

        case
            when category_code = 'unknown' then 1
            else 0
        end as is_unknown_category,

        case
            when brand = 'unknown' then 1
            else 0
        end as is_unknown_brand,

        source_system,
        loaded_at

    from cleaned

)

select *
from final