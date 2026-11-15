provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = "TERRAFORM_SVC"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.terraform_private_key_path)
  role              = "ACCOUNTADMIN"
}