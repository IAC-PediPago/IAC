output "lambda_log_group_names" {
  description = "Nombres de log groups creados para Lambdas"
  value       = [for lg in aws_cloudwatch_log_group.lambda : lg.name]
}

output "api_access_log_group_name" {
  description = "Nombre del log group de access logs del HTTP API (si aplica)"
  value       = length(aws_cloudwatch_log_group.api_access) > 0 ? aws_cloudwatch_log_group.api_access[0].name : null
}

output "api_access_log_group_arn" {
  description = "ARN del log group de access logs del HTTP API (si aplica)"
  value       = length(aws_cloudwatch_log_group.api_access) > 0 ? aws_cloudwatch_log_group.api_access[0].arn : null
}
