output "orders_table_name" {
  value = aws_dynamodb_table.orders.name
}

output "payments_table_name" {
  value = aws_dynamodb_table.payments.name
}

output "products_table_name" {
  value = aws_dynamodb_table.products.name
}

output "orders_table_arn" {
  value = aws_dynamodb_table.orders.arn
}

output "payments_table_arn" {
  value = aws_dynamodb_table.payments.arn
}

output "products_table_arn" {
  value = aws_dynamodb_table.products.arn
}
