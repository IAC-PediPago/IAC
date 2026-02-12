output "orders_lambda_arn" { value = aws_lambda_function.orders.arn }
output "payments_lambda_arn" { value = aws_lambda_function.payments.arn }
output "products_lambda_arn" { value = aws_lambda_function.products.arn }

output "notifications_worker_lambda_arn" { value = aws_lambda_function.notifications_worker.arn }
output "inventory_worker_lambda_arn" { value = aws_lambda_function.inventory_worker.arn }