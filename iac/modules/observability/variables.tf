variable "name_prefix" {
  type        = string
  description = "Prefijo project-env (ej: pedidos-pagos-dev)"
}

variable "tags" {
  type        = map(string)
  description = "Tags base"
  default     = {}
}

variable "log_retention_days" {
  type        = number
  description = "Retención de logs en CloudWatch (días)"
  default     = 14
}

variable "lambda_function_names" {
  type        = list(string)
  description = "Lista de nombres de Lambda para crear /aws/lambda/<name> con retención"
  default     = []
}

variable "enable_api_access_logs" {
  type        = bool
  description = "Si true, crea log group para access logs del HTTP API"
  default     = true
}

variable "api_access_log_group_name" {
  type        = string
  description = "Nombre del log group para access logs del HTTP API"
  default     = null
}