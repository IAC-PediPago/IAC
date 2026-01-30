locals {
  name_prefix = "${var.project_name}-${var.env}"
  account_id  = data.aws_caller_identity.current.account_id
}
