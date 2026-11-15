locals {
  service_users = {
    AIRFLOW_SVC = { role = "LOADER", warehouse = "LOAD_WH", key = "../keys/airflow.pub" }
    DBT_SVC     = { role = "TRANSFORMER", warehouse = "TRANSFORM_WH", key = "../keys/dbt.pub" }
    CI_SVC      = { role = "TRANSFORMER", warehouse = "CI_WH", key = "../keys/ci.pub" }
  }
}

resource "snowflake_service_user" "this" {
  for_each = local.service_users

  name              = each.key
  default_role      = each.value.role
  default_warehouse = each.value.warehouse
  # strip the BEGIN/END lines and all whitespace (handles Windows line endings)
  rsa_public_key = replace(file(each.value.key), "/-----[A-Z ]+-----|\\s/", "")
}

resource "snowflake_grant_account_role" "to_user" {
  for_each  = local.service_users
  role_name = snowflake_account_role.this[each.value.role].name
  user_name = snowflake_service_user.this[each.key].name
}