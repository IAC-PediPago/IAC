variable "name_prefix" {
  type        = string
  description = "Prefijo project-env"
}

variable "aws_region" {
  type        = string
  description = "Región (us-east-1)"
}

variable "tags" {
  type        = map(string)
  description = "Tags base"
  default     = {}
}
