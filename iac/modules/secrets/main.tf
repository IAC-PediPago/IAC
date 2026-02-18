############################
# Secrets Manager (pagos)
# Un solo Secret JSON con Stripe + PayPal + webhook secret
############################

resource "aws_secretsmanager_secret" "payments" {
  name        = coalesce(var.payments_secret_name, "${var.name_prefix}-payments-secrets")
  description = var.payments_secret_description
  tags        = var.tags
}


# Versión inicial (valores placeholder)
# Luego puedes actualizarlo desde consola/CLI sin cambiar Terraform.
resource "aws_secretsmanager_secret_version" "payments" {
  secret_id     = aws_secretsmanager_secret.payments.id
  secret_string = var.payments_secret_json
}
