output "payments_secret_arn" {
  value = aws_secretsmanager_secret.payments.arn
}

output "payments_secret_name" {
  value = aws_secretsmanager_secret.payments.name
}
