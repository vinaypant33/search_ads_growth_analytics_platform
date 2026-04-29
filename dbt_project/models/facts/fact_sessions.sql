with events as (

    select *
    from {{ ref('stg_events') }}

),

sessionized as (

    select
        user_session,

        min(user_id) as user_id,

        min(event_time) as session_start,
        max(event_time) as session_end,

        extract(epoch from (max(event_time) - min(event_time))) / 60.0
            as session_duration_minutes,

        count(*) as events_in_session,

        count(distinct product_id) as unique_products_viewed,

        max(case when event_type = 'view' then 1 else 0 end) as has_view,
        max(case when event_type = 'cart' then 1 else 0 end) as has_cart,
        max(case when event_type = 'purchase' then 1 else 0 end) as has_purchase,

        sum(case when event_type = 'view' then 1 else 0 end) as view_events,
        sum(case when event_type = 'cart' then 1 else 0 end) as cart_events,
        sum(case when event_type = 'purchase' then 1 else 0 end) as purchase_events,

        sum(case when event_type = 'purchase' then price else 0 end)::numeric(12, 2)
            as session_revenue

    from events

    where user_session is not null

    group by user_session

),

classified as (

    select
        *,

        case
            when has_view = 1 and has_cart = 1 and has_purchase = 1
                then 'view_cart_purchase'

            when has_view = 1 and has_cart = 1 and has_purchase = 0
                then 'view_cart_no_purchase'

            when has_view = 1 and has_cart = 0 and has_purchase = 1
                then 'view_purchase_no_cart'

            when has_view = 1 and has_cart = 0 and has_purchase = 0
                then 'view_only'

            when has_view = 0 and has_cart = 1 and has_purchase = 1
                then 'cart_purchase_no_view'

            when has_view = 0 and has_cart = 0 and has_purchase = 1
                then 'purchase_only'

            else 'other'
        end as journey_pattern

    from sessionized

)

select *
from classified