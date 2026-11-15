locals {
  roles = {
    LOADER      = "Writes raw data (Airflow)"
    TRANSFORMER = "Reads RAW, builds ANALYTICS and CI (dbt)"
    REPORTER    = "Reads ANALYTICS (dashboards)"
  }
}

resource "snowflake_account_role" "this" {
  for_each = local.roles
  name     = each.key
  comment  = each.value
}

resource "snowflake_grant_account_role" "to_sysadmin" {
  for_each         = local.roles
  role_name        = snowflake_account_role.this[each.key].name
  parent_role_name = "SYSADMIN"
}