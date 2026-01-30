output "name_prefix" {
  value = local.name_prefix
}

output "account_id" {
  value = local.account_id
}

output "frontend_bucket_name" {
  value = module.frontend_hosting.bucket_name
}

output "frontend_bucket_regional_domain_name" {
  value = module.frontend_hosting.bucket_regional_domain_name
}

output "api_invoke_url" {
  value = module.api_auth.api_invoke_url
}

output "api_origin_domain" {
  value = module.api_auth.api_origin_domain
}

output "cognito_user_pool_id" {
  value = module.api_auth.user_pool_id
}

output "cognito_app_client_id" {
  value = module.api_auth.user_pool_client_id
}

output "cloudfront_domain_name" {
  value = module.edge.cloudfront_domain_name
}

output "orders_table_name" {
  value = module.dynamodb_tables.orders_table_name
}

output "payments_table_name" {
  value = module.dynamodb_tables.payments_table_name
}

output "products_table_name" {
  value = module.dynamodb_tables.products_table_name
}

output "sns_topic_arn" {
  value = module.messaging.sns_topic_arn
}

output "notifications_queue_arn" {
  value = module.messaging.notifications_queue_arn
}

output "inventory_queue_arn" {
  value = module.messaging.inventory_queue_arn
}

output "notifications_dlq_arn" {
  value = module.messaging.notifications_dlq_arn
}

output "inventory_dlq_arn" {
  value = module.messaging.inventory_dlq_arn
}
