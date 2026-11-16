{#- Drops every schema in the target database whose name starts with prefix.
    Matching is done in Jinja, not SQL LIKE, because '_' is a LIKE wildcard
    (PR_1_% would also match PR_12_STAGING). -#}
{% macro drop_pr_schemas(prefix) %}
    {% set results = run_query("show schemas in database " ~ target.database) %}
    {% for row in results %}
        {% set name = row['name'] %}
        {% if name.upper().startswith(prefix.upper()) %}
            {% do log("Dropping " ~ target.database ~ "." ~ name, info=True) %}
            {% do run_query("drop schema if exists " ~ target.database ~ "." ~ name ~ " cascade") %}
        {% endif %}
    {% endfor %}
{% endmacro %}
