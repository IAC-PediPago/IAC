output "orders_create_lambda_arn" { value = aws_lambda_function.orders_create.arn }
output "orders_get_lambda_arn" { value = aws_lambda_function.orders_get.arn }
output "orders_update_status_lambda_arn" { value = aws_lambda_function.orders_update_status.arn }

output "payments_create_lambda_arn" { value = aws_lambda_function.payments_create.arn }
output "payments_webhook_lambda_arn" { value = aws_lambda_function.payments_webhook.arn }

output "products_list_lambda_arn" { value = aws_lambda_function.products_list.arn }

output "notifications_worker_lambda_arn" { value = aws_lambda_function.notifications_worker.arn }
output "inventory_worker_lambda_arn" { value = aws_lambda_function.inventory_worker.arn }

output "lambda_function_names" {
  value = [
    aws_lambda_function.orders_create.function_name,
    aws_lambda_function.orders_get.function_name,
    aws_lambda_function.orders_update_status.function_name,
    aws_lambda_function.payments_create.function_name,
    aws_lambda_function.payments_webhook.function_name,
    aws_lambda_function.products_list.function_name,
    aws_lambda_function.notifications_worker.function_name,
    aws_lambda_function.inventory_worker.function_name
  ]
}