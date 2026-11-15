import csv
import re
import tempfile
from datetime import timedelta
from pathlib import Path

import pendulum
import requests
from airflow.sdk.exceptions import AirflowSkipException
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from airflow.sdk import Asset, Param, dag, get_current_context, task

BASE_URL = "https://data.dft.gov.uk/road-accidents-safety-data"
SCHEMA = "RAW.STATS19"
STAGE = f"{SCHEMA}.STATS19_STAGE"
FILE_FORMAT = f"{SCHEMA}.CSV_FORMAT"
AUDIT_COLS = ["_SOURCE_FILE", "_DATA_YEAR", "_LOADED_AT"]

TABLES = {
    "collision": {"table": "COLLISIONS", "names": ["collision", "accident"]},
    "casualty": {"table": "CASUALTIES", "names": ["casualty"]},
    "vehicle": {"table": "VEHICLES", "names": ["vehicle"]},
}

RAW_STATS19 = Asset(name="raw_stats19", uri="stats19://raw")

def get_hook() -> SnowflakeHook:
    return SnowflakeHook(snowflake_conn_id="snowflake_default")


def resolve_year() -> int:
    """Manual run: use the 'year' param. Scheduled/backfill run: use the logical date."""
    ctx = get_current_context()
    if ctx["params"].get("year"):
        return int(ctx["params"]["year"])
    if ctx.get("logical_date") is None:
        raise ValueError("Manual run with no logical date: trigger with {'year': 2023}")
    return ctx["logical_date"].year


def clean_col(name: str) -> str:
    return re.sub(r"\W", "_", name.strip()).upper()


def download(kind: str, year: int, dest: str) -> Path:
    for name in TABLES[kind]["names"]:
        url = f"{BASE_URL}/dft-road-casualty-statistics-{name}-{year}.csv"
        resp = requests.get(url, timeout=300)
        if resp.status_code == 200:
            path = Path(dest) / f"stats19_{kind}_{year}.csv"
            path.write_bytes(resp.content)
            return path
    raise AirflowSkipException(f"No {kind} file published for {year}")


def ensure_table(hook: SnowflakeHook, table: str, columns: list[str]) -> None:
    """Create the table from the CSV header; add any new columns later years introduce."""
    cols_ddl = ", ".join(f"{c} VARCHAR" for c in columns)
    hook.run(
        f"CREATE TABLE IF NOT EXISTS {SCHEMA}.{table} ("
        f"{cols_ddl}, _SOURCE_FILE VARCHAR, _DATA_YEAR NUMBER, _LOADED_AT TIMESTAMP_NTZ)"
    )
    existing = {
        row[0]
        for row in hook.get_records(
            "SELECT column_name FROM RAW.INFORMATION_SCHEMA.COLUMNS "
            f"WHERE table_schema = 'STATS19' AND table_name = '{table}'"
        )
    }
    for col in columns:
        if col not in existing:
            hook.run(f"ALTER TABLE {SCHEMA}.{table} ADD COLUMN {col} VARCHAR")


@dag(
    schedule="@yearly",
    start_date=pendulum.datetime(2015, 1, 1, tz="UTC"),
    catchup=True,
    max_active_runs=1,
    params={"year": Param(None, type=["null", "integer"])},
    default_args={"retries": 2, "retry_delay": timedelta(minutes=2)},
    tags=["stats19", "ingest"],
)
def ingest_stats19():
    @task
    def setup():
        get_hook().run([
            f"""CREATE FILE FORMAT IF NOT EXISTS {FILE_FORMAT}
                TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"'
                EMPTY_FIELD_AS_NULL = TRUE NULL_IF = ('', 'NULL')""",
            f"CREATE STAGE IF NOT EXISTS {STAGE}",
        ])

    @task
    def load_table(kind: str) -> dict:
        year = resolve_year()
        table = TABLES[kind]["table"]
        hook = get_hook()

        with tempfile.TemporaryDirectory() as tmp:
            path = download(kind, year, tmp)
            with open(path, encoding="utf-8-sig", newline="") as f:  # utf-8-sig strips a BOM
                columns = [clean_col(c) for c in next(csv.reader(f))]
            ensure_table(hook, table, columns)
            hook.run(
                f"PUT 'file://{path.as_posix()}' @{STAGE}/{year}/ "
                "OVERWRITE = TRUE AUTO_COMPRESS = TRUE"
            )
            staged_file = f"{path.name}.gz"

        select_cols = ", ".join(f"${i}" for i in range(1, len(columns) + 1))
        target_cols = ", ".join(columns + AUDIT_COLS)

        # FORCE = TRUE because COPY otherwise skips files it has loaded before.
        hook.run([
            "BEGIN",
            f"DELETE FROM {SCHEMA}.{table} WHERE _DATA_YEAR = {year}",
            f"""COPY INTO {SCHEMA}.{table} ({target_cols})
                FROM (SELECT {select_cols}, METADATA$FILENAME, {year}, CURRENT_TIMESTAMP()
                      FROM @{STAGE}/{year}/{staged_file})
                FILE_FORMAT = (FORMAT_NAME = '{FILE_FORMAT}')
                FORCE = TRUE""",
            "COMMIT",
        ])

        rows = hook.get_first(
            f"SELECT COUNT(*) FROM {SCHEMA}.{table} WHERE _DATA_YEAR = {year}"
        )[0]
        print(f"{table} {year}: {rows} rows")
        return {"table": table, "year": year, "rows": rows}

    @task(outlets=[RAW_STATS19])
    def publish(results: list[dict]):
        """Updating this Asset is what will trigger the dbt DAG in week 4."""
        for r in results:
            print(r)

    loads = load_table.expand(kind=list(TABLES))
    setup() >> loads
    publish(loads)


ingest_stats19()