FROM astrocrpublic.azurecr.io/runtime:3.3-12

# dbt in its own virtualenv so its packages can't clash with Airflow's
RUN python -m venv dbt_venv && \
    dbt_venv/bin/pip install --no-cache-dir "dbt-core>=1.12,<1.13" "dbt-snowflake>=1.12,<1.13"