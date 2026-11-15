with source as (
    select * from {{ source('stats19', 'casualties') }}
),

renamed as (
    select
        -- keys
        {{ dbt_utils.generate_surrogate_key(['collision_index', 'vehicle_reference', 'casualty_reference']) }} as casualty_id,
        {{ dbt_utils.generate_surrogate_key(['collision_index', 'vehicle_reference']) }}                       as vehicle_id,
        collision_index                                        as collision_id,
        try_to_number(collision_year)                          as collision_year,
        try_to_number(vehicle_reference)                       as vehicle_reference,
        try_to_number(casualty_reference)                      as casualty_reference,

        -- who
        {{ clean_code('casualty_class') }}                     as casualty_class_code,
        {{ clean_code('casualty_type') }}                      as casualty_type_code,
        {{ clean_code('sex_of_casualty') }}                    as sex_of_casualty_code,
        {{ clean_code('age_of_casualty') }}                    as age_of_casualty,
        {{ clean_code('age_band_of_casualty') }}               as age_band_of_casualty_code,
        {{ clean_code('casualty_imd_decile') }}                as casualty_imd_decile,
        {{ clean_code('casualty_distance_banding') }}          as casualty_distance_banding_code,
        nullif(lsoa_of_casualty, '-1')                         as casualty_lsoa_code,

        -- pedestrians and passengers
        {{ clean_code('pedestrian_location') }}                as pedestrian_location_code,
        {{ clean_code('pedestrian_movement') }}                as pedestrian_movement_code,
        {{ clean_code('pedestrian_road_maintenance_worker') }} as pedestrian_road_worker_code,
        {{ clean_code('car_passenger') }}                      as car_passenger_code,
        {{ clean_code('bus_or_coach_passenger') }}             as bus_or_coach_passenger_code,

        -- outcome
        {{ clean_code('casualty_severity') }}                  as casualty_severity_code,
        {{ clean_code('enhanced_casualty_severity') }}         as enhanced_casualty_severity_code,
        {{ clean_code('casualty_injury_based') }}              as casualty_injury_based_flag,
        try_to_double(casualty_adjusted_severity_serious)      as adjusted_serious_probability,
        try_to_double(casualty_adjusted_severity_slight)       as adjusted_slight_probability,
        {{ clean_code('escooter_flag') }}                      as escooter_flag,

        -- audit
        _source_file,
        _data_year,
        _loaded_at
    from source
)

select * from renamed
