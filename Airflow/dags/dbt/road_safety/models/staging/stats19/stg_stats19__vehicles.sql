with source as (
    select * from {{ source('stats19', 'vehicles') }}
),

renamed as (
    select
        -- keys
        {{ dbt_utils.generate_surrogate_key(['collision_index', 'vehicle_reference']) }} as vehicle_id,
        collision_index                                        as collision_id,
        try_to_number(collision_year)                          as collision_year,
        try_to_number(vehicle_reference)                       as vehicle_reference,

        -- vehicle
        {{ clean_code('vehicle_type') }}                       as vehicle_type_code,
        {{ clean_code('propulsion_code') }}                    as propulsion_code,
        {{ clean_code('engine_capacity_cc') }}                 as engine_capacity_cc,
        {{ clean_code('age_of_vehicle') }}                     as age_of_vehicle,
        nullif(generic_make_model, '-1')                       as generic_make_model,
        {{ clean_code('vehicle_left_hand_drive') }}            as left_hand_drive_code,
        {{ clean_code('escooter_flag') }}                      as escooter_flag,

        -- what happened
        {{ clean_code('towing_and_articulation') }}            as towing_and_articulation_code,
        {{ clean_code('vehicle_manoeuvre') }}                  as vehicle_manoeuvre_code,
        {{ clean_code('vehicle_direction_from') }}             as direction_from_code,
        {{ clean_code('vehicle_direction_to') }}               as direction_to_code,
        {{ clean_code('vehicle_location_restricted_lane') }}   as restricted_lane_code,
        {{ clean_code('junction_location') }}                  as junction_location_code,
        {{ clean_code('skidding_and_overturning') }}           as skidding_and_overturning_code,
        {{ clean_code('hit_object_in_carriageway') }}          as hit_object_in_carriageway_code,
        {{ clean_code('vehicle_leaving_carriageway') }}        as vehicle_leaving_carriageway_code,
        {{ clean_code('hit_object_off_carriageway') }}         as hit_object_off_carriageway_code,
        {{ clean_code('first_point_of_impact') }}              as first_point_of_impact_code,

        -- driver
        {{ clean_code('journey_purpose_of_driver') }}          as journey_purpose_code,
        {{ clean_code('sex_of_driver') }}                      as sex_of_driver_code,
        {{ clean_code('age_of_driver') }}                      as age_of_driver,
        {{ clean_code('age_band_of_driver') }}                 as age_band_of_driver_code,
        {{ clean_code('driver_imd_decile') }}                  as driver_imd_decile,
        {{ clean_code('driver_distance_banding') }}            as driver_distance_banding_code,
        nullif(lsoa_of_driver, '-1')                           as driver_lsoa_code,

        -- audit
        _source_file,
        _data_year,
        _loaded_at
    from source
)

select * from renamed
