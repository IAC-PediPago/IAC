variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

############################
# Región (para armar ARNs sin data.aws_region)
############################
variable "aws_region" {
  type        = string
  description = "Región AWS (ej: us-east-1)"
}

############################
# API/Auth
############################
variable "api_id" {
  type = string
}

variable "authorizer_id" {
  type = string
}

############################
# DynamoDB ARNs
############################
variable "orders_table_arn" {
  type = string
}

variable "payments_table_arn" {
  type = string
}

variable "products_table_arn" {
  type = string
}

############################
# DynamoDB Names (para env vars)
############################
variable "orders_table_name" {
  type        = string
  description = "Nombre de la tabla DynamoDB de orders"
}

variable "products_table_name" {
  type        = string
  description = "Nombre de la tabla DynamoDB de products"
}

############################
# SNS/SQS ARNs
############################
variable "sns_topic_arn" {
  type = string
}

variable "notifications_queue_arn" {
  type = string
}

variable "inventory_queue_arn" {
  type = string
}

############################
# ZIP paths
############################
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

############################
# Secrets Manager
############################
variable "payments_secret_arn" {
  type        = string
  description = "ARN del secret con credenciales de pagos"
}

############################
# Opcionales (no bloquean si aún no existen)
############################
variable "subnet_ids" {
  type        = list(string)
  description = "Lista de Subnet IDs para Lambdas (opcional). Si está vacía, no se configura VPC."
  default     = []
}

variable "security_group_id" {
  type        = string
  description = "Security Group ID para Lambdas (opcional). Si es null, no se configura VPC."
  default     = null
}

variable "dlq_arn" {
  type        = string
  description = "ARN de DLQ para Lambdas (opcional). Si es null, no se configura DLQ."
  default     = null
}

variable "code_signing_config_arn" {
  type        = string
  description = "ARN del Code Signing Config (opcional)."
  default     = null
}

variable "lambda_kms_key_arn" {
  type        = string
  description = "ARN de KMS Key para cifrar variables de entorno (opcional)."
  default     = null
}

variable "lambda_reserved_concurrency" {
  type        = number
  default     = null
  description = "Reserved concurrency para Lambdas. null desactiva (Terraform usa -1 = unreserved)."
}

variable "payments_table_name" {
  type        = string
  description = "Nombre de la tabla DynamoDB de payments"
}