with conversions as (

    select *
    from {{ ref('fact_conversions') }}

),

products as (

    select *
    from {{ ref('dim_product') }}

),

joined as (

    select
        c.event_date,
        c.event_month,

        c.product_id,
        c.category_id,

        coalesce(p.category_code, 'unknown') as category_code,
        coalesce(p.brand, 'unknown') as brand,

        p.is_unknown_category,
        p.is_unknown_brand,

        c.user_id,
        c.user_session,
        c.conversion_id,
        c.revenue

    from conversions c

    left join products p
        on c.product_id = p.product_id

),

final as (

    select
        event_date,
        event_month,

        category_id,
        category_code,
        brand,

        is_unknown_category,
        is_unknown_brand,

        count(*) as purchase_events,
        count(distinct user_id) as purchasing_users,
        count(distinct user_session) as purchasing_sessions,
        count(distinct product_id) as purchased_products,

        sum(revenue)::numeric(14, 2) as total_revenue,
        avg(revenue)::numeric(12, 2) as avg_purchase_value,
        min(revenue)::numeric(12, 2) as min_purchase_value,
        max(revenue)::numeric(12, 2) as max_purchase_value

    from joined

    group by
        event_date,
        event_month,
        category_id,
        category_code,
        brand,
        is_unknown_category,
        is_unknown_brand

)

select *
from final