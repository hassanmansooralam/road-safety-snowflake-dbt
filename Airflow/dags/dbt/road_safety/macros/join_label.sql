{#- Left-joins the STATS19 code lookup once for one coded column. -#}
{% macro join_label(field_name, code_column, alias) -%}
left join {{ ref('stg_reference__code_lookup') }} as {{ alias }}
    on  {{ alias }}.field_name = '{{ field_name }}'
    and {{ alias }}.code = {{ code_column }}
{%- endmacro %}
