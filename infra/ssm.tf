resource "aws_ssm_parameter" "rails_env" {
  name  = "/${var.project_name}/RAILS_ENV"
  type  = "String"
  value = var.rails_env
}

resource "aws_ssm_parameter" "secret_key_base" {
  name  = "/${var.project_name}/SECRET_KEY_BASE"
  type  = "SecureString"
  value = var.secret_key_base
}

resource "aws_ssm_parameter" "rails_master_key" {
  name  = "/${var.project_name}/RAILS_MASTER_KEY"
  type  = "SecureString"
  value = var.rails_master_key
}