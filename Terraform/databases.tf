resource "snowflake_database" "raw" {
  name    = "RAW"
  comment = "Landing zone for source data, loaded by Airflow"
}

resource "snowflake_schema" "stats19" {
  database = snowflake_database.raw.name
  name     = "STATS19"
}

resource "snowflake_database" "analytics" {
  name    = "ANALYTICS"
  comment = "dbt models; dbt creates its own schemas"
}

resource "snowflake_database" "ci" {
  name    = "CI"
  comment = "Per-PR schemas created by GitHub Actions"
}