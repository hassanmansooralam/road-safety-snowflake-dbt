-- Killed or seriously injured (KSI) casualties by police force and year.
select
    cas.collision_year                             as year,
    pf.police_force_code,
    pf.police_force_name,
    count(*)                                       as casualties,
    count_if(cas.is_killed)                        as killed,
    count_if(cas.is_seriously_injured)             as seriously_injured,
    count_if(cas.is_ksi)                           as ksi,
    round(sum(cas.adjusted_ksi), 1)                as adjusted_ksi,
    round(count_if(cas.is_ksi) / nullif(count(*), 0), 4) as ksi_share
from {{ ref('fct_casualties') }} as cas
left join {{ ref('dim_police_force') }} as pf
    on pf.police_force_code = cas.police_force_code
group by 1, 2, 3
