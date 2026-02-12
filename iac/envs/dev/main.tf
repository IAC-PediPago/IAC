module "frontend_hosting" {
  source      = "../../modules/frontend_hosting"
  name_prefix = local.name_prefix
  account_id  = local.account_id
  tags        = var.tags
}

module "api_auth" {
  source      = "../../modules/api_auth"
  name_prefix = local.name_prefix
  aws_region  = var.aws_region
  tags        = var.tags
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

module "compute" {
  source      = "../../modules/compute/lambdas"
  name_prefix = local.name_prefix
  tags        = var.tags

  api_id        = module.api_auth.api_id
  authorizer_id = module.api_auth.authorizer_id

  orders_table_arn   = module.dynamodb_tables.orders_table_arn
  payments_table_arn = module.dynamodb_tables.payments_table_arn
  products_table_arn = module.dynamodb_tables.products_table_arn

  sns_topic_arn           = module.messaging.sns_topic_arn
  notifications_queue_arn = module.messaging.notifications_queue_arn
  inventory_queue_arn     = module.messaging.inventory_queue_arn

  orders_zip_path               = "${path.module}/../../lambda_artifacts/orders.zip"
  payments_zip_path             = "${path.module}/../../lambda_artifacts/payments.zip"
  products_zip_path             = "${path.module}/../../lambda_artifacts/products.zip"
  notifications_worker_zip_path = "${path.module}/../../lambda_artifacts/notifications_worker.zip"
  inventory_worker_zip_path     = "${path.module}/../../lambda_artifacts/inventory_worker.zip"
}
