variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# API/Auth
variable "api_id" {
  type = string
}

variable "authorizer_id" {
  type = string
}

# DynamoDB ARNs
variable "orders_table_arn" {
  type = string
}

variable "payments_table_arn" {
  type = string
}

variable "products_table_arn" {
  type = string
}

# SNS/SQS ARNs
variable "sns_topic_arn" {
  type = string
}

variable "notifications_queue_arn" {
  type = string
}

variable "inventory_queue_arn" {
  type = string
}

# ZIP paths
variable "orders_zip_path" {
  type = string
}

variable "payments_zip_path" {
  type = string
}

variable "products_zip_path" {
  type = string
}

variable "notifications_worker_zip_path" {
  type = string
}

variable "inventory_worker_zip_path" {
  type = string
}