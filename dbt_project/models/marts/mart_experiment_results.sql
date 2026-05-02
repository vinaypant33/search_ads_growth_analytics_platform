with users as (

    select *
    from {{ ref('dim_user') }}

),

sessions as (

    select *
    from {{ ref('fact_sessions') }}

),

conversions as (

    select *
    from {{ ref('fact_conversions') }}

),

experiment_assignment as (

    select
        user_id,

        'search_ranking_experiment_v1' as experiment_name,

        case
            when mod(abs(hashtext(user_id::text)), 100) < 50 then 'control'
            else 'treatment'
        end as experiment_variant,

        mod(abs(hashtext(user_id::text)), 100) as assignment_bucket,

        first_seen_date as assigned_date

    from users

),

user_session_metrics as (

    select
        user_id,
        count(*) as total_sessions,
        avg(session_duration_minutes)::numeric(12, 2) as avg_session_duration_minutes,
        avg(events_in_session)::numeric(12, 2) as avg_events_per_session,
        sum(has_cart) as sessions_with_cart,
        sum(has_purchase) as sessions_with_purchase

    from sessions
    group by user_id

),

user_conversion_metrics as (

    select
        user_id,
        count(*) as purchase_events,
        sum(revenue)::numeric(14, 2) as total_revenue,
        avg(revenue)::numeric(12, 2) as avg_purchase_value

    from conversions
    group by user_id

),

user_level_experiment_metrics as (

    select
        ea.experiment_name,
        ea.experiment_variant,
        ea.assignment_bucket,
        ea.assigned_date,
        ea.user_id,

        coalesce(usm.total_sessions, 0) as total_sessions,
        coalesce(usm.avg_session_duration_minutes, 0) as avg_session_duration_minutes,
        coalesce(usm.avg_events_per_session, 0) as avg_events_per_session,
        coalesce(usm.sessions_with_cart, 0) as sessions_with_cart,
        coalesce(usm.sessions_with_purchase, 0) as sessions_with_purchase,

        coalesce(ucm.purchase_events, 0) as purchase_events,
        coalesce(ucm.total_revenue, 0) as total_revenue,
        coalesce(ucm.avg_purchase_value, 0) as avg_purchase_value,

        case
            when coalesce(ucm.purchase_events, 0) > 0 then 1
            else 0
        end as is_purchaser

    from experiment_assignment ea

    left join user_session_metrics usm
        on ea.user_id = usm.user_id

    left join user_conversion_metrics ucm
        on ea.user_id = ucm.user_id

),

variant_metrics as (

    select
        experiment_name,
        experiment_variant,

        count(distinct user_id) as users,
        sum(total_sessions) as sessions,
        sum(sessions_with_cart) as sessions_with_cart,
        sum(sessions_with_purchase) as sessions_with_purchase,

        sum(is_purchaser) as purchasers,
        sum(purchase_events) as purchase_events,

        sum(total_revenue)::numeric(14, 2) as total_revenue,

        round(100.0 * sum(is_purchaser) / nullif(count(distinct user_id), 0), 2) as user_conversion_rate,
        round(100.0 * sum(sessions_with_cart) / nullif(sum(total_sessions), 0), 2) as session_cart_rate,
        round(100.0 * sum(sessions_with_purchase) / nullif(sum(total_sessions), 0), 2) as session_purchase_rate,

        round(sum(total_revenue) / nullif(count(distinct user_id), 0), 2) as revenue_per_user,
        round(sum(total_revenue) / nullif(sum(total_sessions), 0), 2) as revenue_per_session,
        round(sum(total_revenue) / nullif(sum(purchase_events), 0), 2) as avg_purchase_value,

        round(avg(avg_session_duration_minutes), 2) as avg_session_duration_minutes,
        round(avg(avg_events_per_session), 2) as avg_events_per_session

    from user_level_experiment_metrics

    group by
        experiment_name,
        experiment_variant

),

control_metrics as (

    select
        experiment_name,

        user_conversion_rate as control_user_conversion_rate,
        revenue_per_user as control_revenue_per_user,
        revenue_per_session as control_revenue_per_session,
        avg_purchase_value as control_avg_purchase_value,
        session_cart_rate as control_session_cart_rate,
        session_purchase_rate as control_session_purchase_rate

    from variant_metrics
    where experiment_variant = 'control'

),

final as (

    select
        vm.experiment_name,
        vm.experiment_variant,

        vm.users,
        vm.sessions,
        vm.sessions_with_cart,
        vm.sessions_with_purchase,
        vm.purchasers,
        vm.purchase_events,
        vm.total_revenue,

        vm.user_conversion_rate,
        vm.session_cart_rate,
        vm.session_purchase_rate,
        vm.revenue_per_user,
        vm.revenue_per_session,
        vm.avg_purchase_value,

        vm.avg_session_duration_minutes,
        vm.avg_events_per_session,

        round(
            100.0 * (vm.user_conversion_rate - cm.control_user_conversion_rate)
            / nullif(cm.control_user_conversion_rate, 0),
            2
        ) as user_conversion_lift_pct,

        round(
            100.0 * (vm.revenue_per_user - cm.control_revenue_per_user)
            / nullif(cm.control_revenue_per_user, 0),
            2
        ) as revenue_per_user_lift_pct,

        round(
            100.0 * (vm.revenue_per_session - cm.control_revenue_per_session)
            / nullif(cm.control_revenue_per_session, 0),
            2
        ) as revenue_per_session_lift_pct,

        round(
            100.0 * (vm.avg_purchase_value - cm.control_avg_purchase_value)
            / nullif(cm.control_avg_purchase_value, 0),
            2
        ) as avg_purchase_value_lift_pct,

        round(
            100.0 * (vm.session_cart_rate - cm.control_session_cart_rate)
            / nullif(cm.control_session_cart_rate, 0),
            2
        ) as session_cart_rate_lift_pct,

        round(
            100.0 * (vm.session_purchase_rate - cm.control_session_purchase_rate)
            / nullif(cm.control_session_purchase_rate, 0),
            2
        ) as session_purchase_rate_lift_pct,

        case
            when vm.experiment_variant = 'control' then 'baseline'
            when vm.user_conversion_rate > cm.control_user_conversion_rate
                 and vm.revenue_per_user > cm.control_revenue_per_user
                then 'positive_lift'
            when vm.user_conversion_rate < cm.control_user_conversion_rate
                 and vm.revenue_per_user < cm.control_revenue_per_user
                then 'negative_lift'
            else 'mixed_result'
        end as experiment_result_status

    from variant_metrics vm

    left join control_metrics cm
        on vm.experiment_name = cm.experiment_name

)

select *
from final