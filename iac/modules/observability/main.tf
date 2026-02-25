########################################
# CloudWatch Logs - Lambdas
########################################
resource "aws_cloudwatch_log_group" "lambda" {
  for_each          = toset(var.lambda_function_names)
  name              = "/aws/lambda/${each.value}"
  retention_in_days = var.log_retention_days

  # opcional: si no quieres que se borren por destroy accidental
  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

########################################
# CloudWatch Logs - API Gateway HTTP API Access Logs
# (El stage se configura en api_auth; aquí solo creamos el destino)
########################################
resource "aws_cloudwatch_log_group" "api_access" {
  count = var.enable_api_access_logs && var.api_access_log_group_name != null ? 1 : 0

  name              = var.api_access_log_group_name
  retention_in_days = var.log_retention_days

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}