resource "snowflake_resource_monitor" "trial" {
  name                      = "TRIAL_MONITOR"
  credit_quota              = var.monthly_credit_quota
  notify_triggers           = [50, 75]
  suspend_trigger           = 90
  suspend_immediate_trigger = 100
}

locals {
  warehouses = {
    LOAD_WH      = "Airflow ingestion"
    TRANSFORM_WH = "dbt runs and dashboard queries"
    CI_WH        = "GitHub Actions CI builds"
  }
}

resource "snowflake_warehouse" "this" {
  for_each = local.warehouses

  name                = each.key
  comment             = each.value
  warehouse_size      = "XSMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  resource_monitor    = snowflake_resource_monitor.trial.fully_qualified_name
}