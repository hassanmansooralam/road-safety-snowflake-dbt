select
    v.*,
    vt.label   as vehicle_type,
    vm.label   as vehicle_manoeuvre,
    pc.label   as propulsion,
    sx.label   as sex_of_driver,
    ab.label   as age_band_of_driver,
    jp.label   as journey_purpose
from {{ ref('stg_stats19__vehicles') }} as v
{{ join_label('vehicle_type',              'v.vehicle_type_code',       'vt') }}
{{ join_label('vehicle_manoeuvre',         'v.vehicle_manoeuvre_code',  'vm') }}
{{ join_label('propulsion_code',           'v.propulsion_code',         'pc') }}
{{ join_label('sex_of_driver',             'v.sex_of_driver_code',      'sx') }}
{{ join_label('age_band_of_driver',        'v.age_band_of_driver_code', 'ab') }}
{{ join_label('journey_purpose_of_driver', 'v.journey_purpose_code',    'jp') }}
