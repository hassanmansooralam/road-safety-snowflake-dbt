-- One label per (field_name, code). The DfT guide repeats some fields across
-- tables (e.g. escooter_flag), so collapse them here to stop joins fanning out.
select
    field_name,
    code,
    min(label) as label
from {{ ref('stats19_code_lookup') }}
group by field_name, code
