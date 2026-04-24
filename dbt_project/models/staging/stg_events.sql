with source as (

    select *
    from {{ source('raw', 'raw_events') }}

),

cleaned as (

    select
        event_id,

        event_time,
        cast(event_time as date) as event_date,
        extract(hour from event_time) as event_hour,
        extract(dow from event_time) as event_day_of_week,
        date_trunc('month', event_time)::date as event_month,

        lower(trim(event_type)) as event_type,

        product_id,
        category_id,
        price::numeric(12, 2) as price,

        user_id,
        nullif(trim(user_session), '') as user_session,

        source_file,
        loaded_at

    from source
    where event_time is not null
      and event_type is not null
      and product_id is not null
      and user_id is not null
      and lower(trim(event_type)) in ('view', 'cart', 'purchase')

)

select *
from cleaned