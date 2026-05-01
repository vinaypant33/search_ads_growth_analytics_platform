with date_spine as (

    select
        generate_series(
            (select min(event_date) from {{ ref('stg_events') }}),
            (select max(event_date) from {{ ref('stg_events') }}),
            interval '1 day'
        )::date as date_day

),

final as (

    select
        date_day,

        extract(day from date_day) as day_of_month,
        extract(month from date_day) as month_number,
        extract(year from date_day) as year_number,
        extract(quarter from date_day) as quarter_number,

        extract(dow from date_day) as day_of_week_number,
        to_char(date_day, 'Day') as day_of_week_name,
        to_char(date_day, 'Month') as month_name,

        date_trunc('week', date_day)::date as week_start_date,
        date_trunc('month', date_day)::date as month_start_date,
        date_trunc('quarter', date_day)::date as quarter_start_date,
        date_trunc('year', date_day)::date as year_start_date,

        case
            when extract(dow from date_day) in (0, 6) then 1
            else 0
        end as is_weekend

    from date_spine

)

select *
from final