select
    c.*,
    sev.label  as collision_severity,
    pf.label   as police_force,
    dow.label  as day_of_week,
    rt.label   as road_type,
    jd.label   as junction_detail,
    lc.label   as light_conditions,
    wc.label   as weather_conditions,
    rs.label   as road_surface_conditions,
    ur.label   as urban_or_rural
from {{ ref('stg_stats19__collisions') }} as c
{{ join_label('collision_severity',      'c.collision_severity_code',      'sev') }}
{{ join_label('police_force',            'c.police_force_code',            'pf') }}
{{ join_label('day_of_week',             'c.day_of_week_code',             'dow') }}
{{ join_label('road_type',               'c.road_type_code',               'rt') }}
{{ join_label('junction_detail',         'c.junction_detail_code',         'jd') }}
{{ join_label('light_conditions',        'c.light_conditions_code',        'lc') }}
{{ join_label('weather_conditions',      'c.weather_conditions_code',      'wc') }}
{{ join_label('road_surface_conditions', 'c.road_surface_conditions_code', 'rs') }}
{{ join_label('urban_or_rural_area',     'c.urban_or_rural_code',          'ur') }}
