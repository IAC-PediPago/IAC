variable "name_prefix" {
  type        = string
  description = "Prefijo project-env"
}

variable "tags" {
  type        = map(string)
  description = "Tags base"
  default     = {}
}

# S3 frontend origin
variable "frontend_bucket_name" {
  type        = string
  description = "Nombre del bucket frontend"
}

variable "frontend_bucket_arn" {
  type        = string
  description = "ARN del bucket frontend"
}

variable "frontend_bucket_regional_domain_name" {
  type        = string
  description = "Regional domain name del bucket (origin CloudFront)"
}

# API origin (ya existe desde 2.3)
variable "api_origin_domain" {
  type        = string
  description = "Dominio del API Gateway (sin https://). Ej: xxxx.execute-api.us-east-1.amazonaws.com"
}

# Route53 opcional
variable "enable_route53" {
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  type        = string
  default     = ""
}

variable "route53_record_name" {
  type        = string
  default     = ""
}

# Certificado opcional (si usas dominio real)
variable "acm_certificate_arn" {
  type        = string
  default     = ""
}
