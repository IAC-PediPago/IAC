############################
# Cognito User Pool
############################
resource "aws_cognito_user_pool" "users" {
  name = "${var.name_prefix}-user-pool"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.name_prefix}-app-client"
  user_pool_id = aws_cognito_user_pool.users.id

  generate_secret               = false
  supported_identity_providers  = ["COGNITO"]
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

############################
# API Gateway HTTP API (público)
############################
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.name_prefix}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
  }

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  tags = var.tags
}

############################
# JWT Authorizer (Cognito)
############################
locals {
  issuer = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id          = aws_apigatewayv2_api.http_api.id
  name            = "${var.name_prefix}-jwt-authorizer"
  authorizer_type = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = local.issuer
    audience = [aws_cognito_user_pool_client.app.id]
  }
}
