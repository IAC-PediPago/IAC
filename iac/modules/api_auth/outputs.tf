output "api_id" {
  value = aws_apigatewayv2_api.http_api.id
}

output "api_invoke_url" {
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

output "jwt_issuer" {
  value = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
}
