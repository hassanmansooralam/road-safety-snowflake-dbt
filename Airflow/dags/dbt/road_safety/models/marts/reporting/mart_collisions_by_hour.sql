-- Average collisions per day for each hour, weekdays vs weekends (2021-2025).
with counts as (
    select
        hour(c.collision_at)                          as hour_of_day,
        d.is_weekend,
        count(*)                                      as collisions
    from {{ ref('fct_collisions') }} as c
    inner join {{ ref('dim_date') }} as d
        on d.date_day = c.collision_date
    group by 1, 2
),

days as (
    select is_weekend, count(*) as n_days
    from {{ ref('dim_date') }}
    group by 1
)

select
    c.hour_of_day,
    round(max(iff(not c.is_weekend, c.collisions / d.n_days, null)), 1) as weekday_avg,
    round(max(iff(c.is_weekend,     c.collisions / d.n_days, null)), 1) as weekend_avg
from counts as c
inner join days as d
    on d.is_weekend = c.is_weekend
group by c.hour_of_day
order by c.hour_of_day