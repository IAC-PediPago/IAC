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

############################
# Cognito App Client
############################
resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.name_prefix}-app-client"
  user_pool_id = aws_cognito_user_pool.users.id

  generate_secret               = false
  supported_identity_providers  = ["COGNITO"]
  prevent_user_existence_errors = "ENABLED"

  # Mantiene tu login actual (email+password / SRP)
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # (Opcional) si luego quieres frontend con flows OAuth; no rompe login directo
  allowed_oauth_flows_user_pool_client = false
}

############################
# API Gateway HTTP API
############################
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.name_prefix}-http-api"
  protocol_type = "HTTP"

  # CORS (en dev puede ser abierto; en prod conviene restringir)
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    expose_headers = ["content-type"]
    max_age = 3600
  }

  tags = var.tags
}

############################
# Stage default + Access logs (CloudWatch)
############################
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  dynamic "access_log_settings" {
    for_each = var.enable_access_logs && var.access_log_destination_arn != null && var.access_log_format != null ? [1] : []
    content {
      destination_arn = var.access_log_destination_arn
      format          = var.access_log_format
    }
  }

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