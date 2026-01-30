variable "name_prefix" {
  type        = string
  description = "Prefijo estándar: project-env"
}

variable "account_id" {
  type        = string
  description = "Account ID para hacer el bucket único globalmente"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}
