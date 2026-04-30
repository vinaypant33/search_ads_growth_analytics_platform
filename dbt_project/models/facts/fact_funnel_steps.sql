with events as (

    select *
    from {{ ref('stg_events') }}

),

daily_funnel as (

    select
        event_date,

        count(*) as total_events,

        sum(case when event_type = 'view' then 1 else 0 end) as view_events,
        sum(case when event_type = 'cart' then 1 else 0 end) as cart_events,
        sum(case when event_type = 'purchase' then 1 else 0 end) as purchase_events,

        count(distinct user_id) as active_users,
        count(distinct user_session) as sessions,

        count(distinct case when event_type = 'view' then user_session end) as sessions_with_view,
        count(distinct case when event_type = 'cart' then user_session end) as sessions_with_cart,
        count(distinct case when event_type = 'purchase' then user_session end) as sessions_with_purchase

    from events
    group by event_date

),

final as (

    select
        event_date,

        total_events,
        active_users,
        sessions,

        view_events,
        cart_events,
        purchase_events,

        sessions_with_view,
        sessions_with_cart,
        sessions_with_purchase,

        round(100.0 * cart_events / nullif(view_events, 0), 2) as event_view_to_cart_rate,
        round(100.0 * purchase_events / nullif(cart_events, 0), 2) as event_cart_to_purchase_rate,
        round(100.0 * purchase_events / nullif(view_events, 0), 2) as event_view_to_purchase_rate,

        round(100.0 * sessions_with_cart / nullif(sessions_with_view, 0), 2) as session_view_to_cart_rate,
        round(100.0 * sessions_with_purchase / nullif(sessions_with_cart, 0), 2) as session_cart_to_purchase_rate,
        round(100.0 * sessions_with_purchase / nullif(sessions_with_view, 0), 2) as session_view_to_purchase_rate

    from daily_funnel

)

select *
from final