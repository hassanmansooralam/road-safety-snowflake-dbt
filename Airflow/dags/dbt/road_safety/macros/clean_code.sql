{% macro clean_code(column) -%}
    nullif(try_to_number({{ column }}), -1)
{%- endmacro %}
