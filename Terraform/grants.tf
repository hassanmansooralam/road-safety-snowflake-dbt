# --- Warehouse usage ---
locals {
  wh_grants = {
    loader_load        = { role = "LOADER", wh = "LOAD_WH" }
    transformer_tf     = { role = "TRANSFORMER", wh = "TRANSFORM_WH" }
    transformer_ci     = { role = "TRANSFORMER", wh = "CI_WH" }
    reporter_transform = { role = "REPORTER", wh = "TRANSFORM_WH" }
  }
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  for_each          = local.wh_grants
  account_role_name = snowflake_account_role.this[each.value.role].name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.this[each.value.wh].name
  }
}

# --- LOADER: write into RAW.STATS19 ---
resource "snowflake_grant_privileges_to_account_role" "loader_raw_db" {
  account_role_name = snowflake_account_role.this["LOADER"].name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_raw_schema" {
  account_role_name = snowflake_account_role.this["LOADER"].name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE STAGE", "CREATE FILE FORMAT"]
  on_schema {
    schema_name = snowflake_schema.stats19.fully_qualified_name
  }
}

# --- TRANSFORMER: read RAW ---
resource "snowflake_grant_privileges_to_account_role" "transformer_raw_db" {
  account_role_name = snowflake_account_role.this["TRANSFORMER"].name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "transformer_raw_schema" {
  account_role_name = snowflake_account_role.this["TRANSFORMER"].name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = snowflake_schema.stats19.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "transformer_raw_future_tables" {
  account_role_name = snowflake_account_role.this["TRANSFORMER"].name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.stats19.fully_qualified_name
    }
  }
}

# --- TRANSFORMER: build in ANALYTICS and CI (dbt creates schemas) ---
resource "snowflake_grant_privileges_to_account_role" "transformer_build_dbs" {
  for_each          = { analytics = snowflake_database.analytics.name, ci = snowflake_database.ci.name }
  account_role_name = snowflake_account_role.this["TRANSFORMER"].name
  privileges        = ["USAGE", "CREATE SCHEMA"]
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value
  }
}

# --- REPORTER: read ANALYTICS ---
resource "snowflake_grant_privileges_to_account_role" "reporter_db" {
  account_role_name = snowflake_account_role.this["REPORTER"].name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.analytics.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "reporter_future_schemas" {
  account_role_name = snowflake_account_role.this["REPORTER"].name
  privileges        = ["USAGE"]
  on_schema {
    future_schemas_in_database = snowflake_database.analytics.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "reporter_future_objects" {
  for_each          = toset(["TABLES", "VIEWS"])
  account_role_name = snowflake_account_role.this["REPORTER"].name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = each.value
      in_database        = snowflake_database.analytics.name
    }
  }
}