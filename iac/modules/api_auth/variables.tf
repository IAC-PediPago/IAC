variable "name_prefix" {
  type        = string
  description = "Prefijo project-env"
}

variable "aws_region" {
  type        = string
  description = "Región AWS (ej: us-east-1)"
}

variable "tags" {
  type        = map(string)
  description = "Tags base"
  default     = {}
}

############################
# Observabilidad (Access Logs HTTP API)
############################
variable "enable_access_logs" {
  type        = bool
  description = "Habilitar access logs en el stage $default del HTTP API"
  default     = true
}

variable "access_log_destination_arn" {
  type        = string
  description = "ARN del CloudWatch Log Group destino para access logs"
  default     = null
}

variable "access_log_format" {
  type        = string
  description = "Formato (JSON) de access logs para API Gateway HTTP API"
  default     = null
}