select
    code   as police_force_code,
    label  as police_force_name
from {{ ref('stg_reference__code_lookup') }}
where field_name = 'police_force'
