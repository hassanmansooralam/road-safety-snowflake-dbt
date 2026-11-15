-- Grain: one row per reported collision.
select
    collision_id,
    collision_date,
    collision_at,
    collision_year,
    police_force_code,
    local_authority_ons_code,

    collision_severity_code,
    collision_severity,
    collision_severity_code = 1                    as is_fatal,
    collision_severity_code in (1, 2)              as is_ksi,

    speed_limit_mph,
    road_type,
    junction_detail,
    light_conditions,
    weather_conditions,
    road_surface_conditions,
    urban_or_rural,

    number_of_vehicles,
    number_of_casualties,
    latitude,
    longitude,

    _data_year
from {{ ref('int_stats19__collisions_labelled') }}
