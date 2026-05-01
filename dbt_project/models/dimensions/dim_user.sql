with events as (

    select *
    from {{ ref('stg_events') }}

),

sessions as (

    select *
    from {{ ref('fact_sessions') }}

),

conversions as (

    select *
    from {{ ref('fact_conversions') }}

),

user_events as (

    select
        user_id,

        min(event_time) as first_seen_at,
        max(event_time) as last_seen_at,

        min(event_date) as first_seen_date,
        max(event_date) as last_seen_date,

        count(*) as total_events,
        count(distinct user_session) as total_sessions,
        count(distinct product_id) as total_products_interacted,

        sum(case when event_type = 'view' then 1 else 0 end) as total_view_events,
        sum(case when event_type = 'cart' then 1 else 0 end) as total_cart_events,
        sum(case when event_type = 'purchase' then 1 else 0 end) as total_purchase_events

    from events
    group by user_id

),

user_sessions as (

    select
        user_id,

        count(*) as session_count,
        avg(session_duration_minutes) as avg_session_duration_minutes,
        avg(events_in_session) as avg_events_per_session,

        max(has_view) as has_ever_viewed,
        max(has_cart) as has_ever_carted,
        max(has_purchase) as has_ever_purchased

    from sessions
    group by user_id

),

user_revenue as (

    select
        user_id,

        count(*) as conversion_count,
        sum(revenue)::numeric(12, 2) as total_revenue,
        avg(revenue)::numeric(12, 2) as avg_purchase_value

    from conversions
    group by user_id

),

final as (

    select
        ue.user_id,

        ue.first_seen_at,
        ue.last_seen_at,
        ue.first_seen_date,
        ue.last_seen_date,

        ue.total_events,
        ue.total_sessions,
        ue.total_products_interacted,

        ue.total_view_events,
        ue.total_cart_events,
        ue.total_purchase_events,

        coalesce(us.session_count, 0) as session_count,
        coalesce(round(us.avg_session_duration_minutes::numeric, 2), 0) as avg_session_duration_minutes,
        coalesce(round(us.avg_events_per_session::numeric, 2), 0) as avg_events_per_session,

        coalesce(us.has_ever_viewed, 0) as has_ever_viewed,
        coalesce(us.has_ever_carted, 0) as has_ever_carted,
        coalesce(us.has_ever_purchased, 0) as has_ever_purchased,

        coalesce(ur.conversion_count, 0) as conversion_count,
        coalesce(ur.total_revenue, 0) as total_revenue,
        coalesce(ur.avg_purchase_value, 0) as avg_purchase_value,

        case
            when coalesce(ur.conversion_count, 0) > 0
                then 'purchaser'

            when coalesce(us.has_ever_carted, 0) = 1
                then 'carted_not_purchased'

            when coalesce(us.has_ever_viewed, 0) = 1
                then 'viewer_only'

            else 'other'
        end as user_segment

    from user_events ue

    left join user_sessions us
        on ue.user_id = us.user_id

    left join user_revenue ur
        on ue.user_id = ur.user_id

)

select *
from final