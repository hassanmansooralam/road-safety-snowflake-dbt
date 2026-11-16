{{
    config(
        materialized='incremental',
        unique_key='casualty_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns'
    )
}}

-- Grain: one row per casualty, with the collision context needed for analysis.
select
    cas.casualty_id,
    cas.collision_id,
    cas.vehicle_id,
    col.collision_date,
    col.collision_year,
    col.police_force_code,

    cas.casualty_class,
    cas.casualty_type,
    cas.sex_of_casualty,
    cas.age_of_casualty,
    cas.age_band_of_casualty,

    cas.casualty_severity_code,
    cas.casualty_severity,
    cas.casualty_severity_code = 1                 as is_killed,
    cas.casualty_severity_code = 2                 as is_seriously_injured,
    cas.casualty_severity_code in (1, 2)           as is_ksi,

    -- DfT adjusted estimate: fatal counts as 1, otherwise the modelled
    -- probability that the casualty was seriously injured.
    iff(cas.casualty_severity_code = 1, 1, coalesce(cas.adjusted_serious_probability, 0))
                                                   as adjusted_ksi,

    col.speed_limit_mph,
    col.road_type,
    col.light_conditions,
    col.weather_conditions,
    col.urban_or_rural,

    cas._data_year,
    cas._loaded_at
from {{ ref('int_stats19__casualties_labelled') }} as cas
inner join {{ ref('int_stats19__collisions_labelled') }} as col
    on col.collision_id = cas.collision_id



{% if is_incremental() %}
-- Only rows loaded since the last build. A re-loaded year gets a new _loaded_at,
-- so it is picked up and merged on casualty_id.
where cas._loaded_at > (select max(_loaded_at) from {{ this }})
{% endif %}
