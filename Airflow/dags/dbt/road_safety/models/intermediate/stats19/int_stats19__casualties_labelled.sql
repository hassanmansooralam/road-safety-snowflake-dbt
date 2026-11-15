select
    c.*,
    cc.label   as casualty_class,
    ct.label   as casualty_type,
    sx.label   as sex_of_casualty,
    ab.label   as age_band_of_casualty,
    sev.label  as casualty_severity
from {{ ref('stg_stats19__casualties') }} as c
{{ join_label('casualty_class',       'c.casualty_class_code',       'cc') }}
{{ join_label('casualty_type',        'c.casualty_type_code',        'ct') }}
{{ join_label('sex_of_casualty',      'c.sex_of_casualty_code',      'sx') }}
{{ join_label('age_band_of_casualty', 'c.age_band_of_casualty_code', 'ab') }}
{{ join_label('casualty_severity',    'c.casualty_severity_code',    'sev') }}
