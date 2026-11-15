from pathlib import Path

import pendulum
from airflow.sdk import Asset
from cosmos import DbtDag, ExecutionConfig, ProfileConfig, ProjectConfig, RenderConfig

AIRFLOW_HOME = Path("/usr/local/airflow")
DBT_PROJECT_PATH = AIRFLOW_HOME / "dags" / "dbt" / "road_safety"
DBT_EXECUTABLE = AIRFLOW_HOME / "dbt_venv" / "bin" / "dbt"

# Must match the asset in ingest_data.py exactly (same name and uri)
RAW_STATS19 = Asset(name="raw_stats19", uri="stats19://raw")

transform_dbt = DbtDag(
    dag_id="transform_dbt",
    project_config=ProjectConfig(dbt_project_path=DBT_PROJECT_PATH),
    profile_config=ProfileConfig(
        profile_name="road_safety",
        target_name="dev",
        profiles_yml_filepath=AIRFLOW_HOME / "include" / "dbt" / "profiles.yml",
    ),
    execution_config=ExecutionConfig(dbt_executable_path=str(DBT_EXECUTABLE)),
    render_config=RenderConfig(dbt_deps=True),
    operator_args={"install_deps": True},
    schedule=[RAW_STATS19],          # runs whenever ingest_stats19 publishes new data
    start_date=pendulum.datetime(2021, 1, 1, tz="UTC"),
    catchup=False,
    max_active_runs=1,
    default_args={"retries": 1},
    tags=["dbt", "stats19", "transform"],
)