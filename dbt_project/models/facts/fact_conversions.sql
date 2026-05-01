with events as (

    select *
    from {{ ref('stg_events') }}

),

conversions as (

    select
        event_id as conversion_id,
        event_time,
        event_date,
        event_hour,
        event_day_of_week,
        event_month,

        user_id,
        user_session,

        product_id,
        category_id,

        price::numeric(12, 2) as revenue,

        case
            when price is null then 1
            else 0
        end as is_missing_revenue,

        source_file,
        loaded_at

    from events
    where event_type = 'purchase'

)

select *
from conversions