variable "snowflake_organization" { type = string }
variable "snowflake_account" { type = string }

variable "terraform_private_key_path" {
  type = string
}

variable "monthly_credit_quota" {
  type    = number
  default = 50
}