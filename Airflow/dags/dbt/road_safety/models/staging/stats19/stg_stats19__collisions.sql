with source as (
    select * from {{ source('stats19', 'collisions') }}
),

renamed as (
    select
        -- keys
        collision_index                                        as collision_id,
        try_to_number(collision_year)                          as collision_year,
        collision_ref_no                                       as collision_reference,

        -- when
        coalesce(
            try_to_date("DATE", 'DD/MM/YYYY'),
            try_to_date("DATE", 'YYYY-MM-DD')
        )                                                      as collision_date,
        try_to_time("TIME", 'HH24:MI')                         as collision_time,
        {{ clean_code('day_of_week') }}                        as day_of_week_code,

        -- where
        try_to_number(location_easting_osgr)                   as easting_osgr,
        try_to_number(location_northing_osgr)                  as northing_osgr,
        try_to_double(longitude)                               as longitude,
        try_to_double(latitude)                                as latitude,
        {{ clean_code('police_force') }}                       as police_force_code,
        {{ clean_code('local_authority_district') }}           as local_authority_district_code,
        nullif(local_authority_ons_district, '-1')             as local_authority_ons_code,
        nullif(local_authority_highway, '-1')                  as local_authority_highway_code,
        {{ clean_code('urban_or_rural_area') }}                as urban_or_rural_code,
        nullif(lsoa_of_accident_location, '-1')                as lsoa_code,

        -- road
        {{ clean_code('first_road_class') }}                   as first_road_class_code,
        {{ clean_code('first_road_number') }}                  as first_road_number,
        {{ clean_code('second_road_class') }}                  as second_road_class_code,
        {{ clean_code('second_road_number') }}                 as second_road_number,
        {{ clean_code('road_type') }}                          as road_type_code,
        {{ clean_code('speed_limit') }}                        as speed_limit_mph,
        {{ clean_code('junction_detail') }}                    as junction_detail_code,
        {{ clean_code('junction_control') }}                   as junction_control_code,
        {{ clean_code('pedestrian_crossing') }}                as pedestrian_crossing_code,
        {{ clean_code('trunk_road_flag') }}                    as trunk_road_flag_code,

        -- conditions
        {{ clean_code('light_conditions') }}                   as light_conditions_code,
        {{ clean_code('weather_conditions') }}                 as weather_conditions_code,
        {{ clean_code('road_surface_conditions') }}            as road_surface_conditions_code,
        {{ clean_code('special_conditions_at_site') }}         as special_conditions_code,
        {{ clean_code('carriageway_hazards') }}                as carriageway_hazards_code,

        -- outcome
        {{ clean_code('collision_severity') }}                 as collision_severity_code,
        try_to_double(collision_adjusted_severity_serious)     as adjusted_serious_probability,
        try_to_double(collision_adjusted_severity_slight)      as adjusted_slight_probability,
        try_to_number(number_of_vehicles)                      as number_of_vehicles,
        try_to_number(number_of_casualties)                    as number_of_casualties,
        {{ clean_code('did_police_officer_attend_scene_of_accident') }} as police_attended_code,

        -- audit
        _source_file,
        _data_year,
        _loaded_at
    from source
)

select
    *,
    timestamp_ntz_from_parts(collision_date, collision_time) as collision_at
from renamed
