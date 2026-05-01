with funnel as (

    select *
    from {{ ref('fact_funnel_steps') }}

),

conversions as (

    select *
    from {{ ref('fact_conversions') }}

),

date_dim as (

    select *
    from {{ ref('dim_date') }}

),

daily_revenue as (

    select
        event_date,

        count(*) as purchase_events,
        count(distinct user_id) as purchasing_users,
        count(distinct user_session) as purchasing_sessions,

        sum(revenue)::numeric(14, 2) as total_revenue,
        avg(revenue)::numeric(12, 2) as avg_purchase_value

    from conversions
    group by event_date

),

final as (

    select
        f.event_date,

        d.day_of_month,
        d.month_number,
        d.month_name,
        d.year_number,
        d.quarter_number,
        d.day_of_week_number,
        d.day_of_week_name,
        d.week_start_date,
        d.month_start_date,
        d.is_weekend,

        f.total_events,
        f.active_users,
        f.sessions,

        f.view_events,
        f.cart_events,
        f.purchase_events as funnel_purchase_events,

        coalesce(r.purchase_events, 0) as purchase_events,
        coalesce(r.purchasing_users, 0) as purchasing_users,
        coalesce(r.purchasing_sessions, 0) as purchasing_sessions,
        coalesce(r.total_revenue, 0) as total_revenue,
        coalesce(r.avg_purchase_value, 0) as avg_purchase_value,

        f.sessions_with_view,
        f.sessions_with_cart,
        f.sessions_with_purchase,

        f.event_view_to_cart_rate,
        f.event_cart_to_purchase_rate,
        f.event_view_to_purchase_rate,

        f.session_view_to_cart_rate,
        f.session_cart_to_purchase_rate,
        f.session_view_to_purchase_rate,

        round(coalesce(r.total_revenue, 0) / nullif(f.active_users, 0), 2) as revenue_per_active_user,
        round(coalesce(r.total_revenue, 0) / nullif(f.sessions, 0), 2) as revenue_per_session,
        round(coalesce(r.purchase_events, 0)::numeric / nullif(f.sessions, 0) * 100, 2) as purchase_events_per_session_pct

    from funnel f

    left join daily_revenue r
        on f.event_date = r.event_date

    left join date_dim d
        on f.event_date = d.date_day

)

select *
from final