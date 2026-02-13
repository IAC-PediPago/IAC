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

# Secrets Manager
variable "payments_secret_arn" {
  type        = string
  description = "ARN del secret con credenciales de pagos"
}
variable "subnet_ids" {
  description = "Lista de IDs de subnets para la VPC"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del Security Group para la Lambda"
  type        = string
}

#E_272
variable "code_signing_config_arn" {
  description = "ARN del sello de seguridad para validar el código de la Lambda"
  type        = string
  default     = null 
}

#E_173
variable "code_signing_config_arn" {
  type    = string
  default = null
}

variable "lambda_kms_key_arn" {
  type    = string
  default = null
}

#-116
variable "dlq_arn" {
  description = "ARN de la cola SQS para manejar fallos de la Lambda (DLQ)"
  type        = string
}

#E_117
variable "subnet_ids" {
  description = "Lista de IDs de las subredes donde correra la Lambda"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del grupo de seguridad para la Lambda"
  type        = string
}