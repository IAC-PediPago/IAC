module "frontend_hosting" {
  source      = "../../modules/frontend_hosting"
  name_prefix = local.name_prefix
  account_id  = local.account_id
  tags        = var.tags
}

# Observabilidad primero (rompe dependencia circular)
module "observability" {
  source      = "../../modules/observability"
  name_prefix = local.name_prefix
  tags        = var.tags

  log_retention_days = 14

  # Nombres determinísticos (no depende del módulo compute)
  lambda_function_names = [
    "${local.name_prefix}-orders",
    "${local.name_prefix}-payments",
    "${local.name_prefix}-products",
    "${local.name_prefix}-notifications-worker",
    "${local.name_prefix}-inventory-worker"
  ]

  enable_api_access_logs    = true
  api_access_log_group_name = "/aws/apigateway/${local.name_prefix}-http-api-access"
}

module "api_auth" {
  source      = "../../modules/api_auth"
  name_prefix = local.name_prefix
  aws_region  = var.aws_region
  tags        = var.tags

  enable_access_logs         = true
  access_log_destination_arn = module.observability.api_access_log_group_arn
  access_log_format = jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    routeKey       = "$context.routeKey"
    status         = "$context.status"
    responseLength = "$context.responseLength"
    userAgent      = "$context.identity.userAgent"
  })
}

module "edge" {
  source = "../../modules/edge"

  name_prefix = local.name_prefix
  tags        = var.tags

  frontend_bucket_name                 = module.frontend_hosting.bucket_name
  frontend_bucket_arn                  = module.frontend_hosting.bucket_arn
  frontend_bucket_regional_domain_name = module.frontend_hosting.bucket_regional_domain_name

  api_origin_domain = module.api_auth.api_origin_domain

  # placeholder (sin dominio real)
  enable_route53      = false
  route53_zone_id     = ""
  route53_record_name = ""
  acm_certificate_arn = ""
}

module "dynamodb_tables" {
  source      = "../../modules/data/dynamodb_tables"
  name_prefix = local.name_prefix
  tags        = var.tags
}

module "messaging" {
  source      = "../../modules/messaging/sns_sqs"
  name_prefix = local.name_prefix
  tags        = var.tags
}

############################
# Secrets Manager
############################
module "secrets_manager" {
  source      = "../../modules/secrets"
  name_prefix = local.name_prefix
  tags        = var.tags
}

module "compute" {
  source      = "../../modules/compute/lambdas"
  name_prefix = local.name_prefix
  tags        = var.tags

  aws_region    = var.aws_region
  api_id        = module.api_auth.api_id
  authorizer_id = module.api_auth.authorizer_id

  orders_table_arn   = module.dynamodb_tables.orders_table_arn
  payments_table_arn = module.dynamodb_tables.payments_table_arn
  products_table_arn = module.dynamodb_tables.products_table_arn

  sns_topic_arn           = module.messaging.sns_topic_arn
  notifications_queue_arn = module.messaging.notifications_queue_arn
  inventory_queue_arn     = module.messaging.inventory_queue_arn

  payments_secret_arn = module.secrets_manager.payments_secret_arn

  orders_zip_path               = "${path.module}/../../lambda_artifacts/orders.zip"
  payments_zip_path             = "${path.module}/../../lambda_artifacts/payments.zip"
  products_zip_path             = "${path.module}/../../lambda_artifacts/products.zip"
  notifications_worker_zip_path = "${path.module}/../../lambda_artifacts/notifications_worker.zip"
  inventory_worker_zip_path     = "${path.module}/../../lambda_artifacts/inventory_worker.zip"

  lambda_reserved_concurrency = null
}
