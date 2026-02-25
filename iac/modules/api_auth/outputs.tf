output "api_id" {
  value = aws_apigatewayv2_api.http_api.id
}

# Mantengo tu nombre actual
output "api_invoke_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

# Alias útil (opcional)
output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "api_origin_domain" {
  value = replace(aws_apigatewayv2_api.http_api.api_endpoint, "https://", "")
}

output "authorizer_id" {
  value = aws_apigatewayv2_authorizer.jwt.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.users.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.app.id
}

# Mantengo tu output, pero idealmente que coincida con local.issuer
output "jwt_issuer" {
  value = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
}

# Alias más genérico (opcional)
output "issuer" {
  value = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
}

output "api_stage_name" {
  value = aws_apigatewayv2_stage.default.name
}