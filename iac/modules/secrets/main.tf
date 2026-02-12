locals {
  payments_secret_name_final = coalesce(var.payments_secret_name, "${var.name_prefix}-payments-secrets")
}

resource "aws_secretsmanager_secret" "payments" {
  name        = local.payments_secret_name_final
  description = var.payments_secret_description
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "payments" {
  secret_id     = aws_secretsmanager_secret.payments.id
  secret_string = var.payments_secret_json
}
