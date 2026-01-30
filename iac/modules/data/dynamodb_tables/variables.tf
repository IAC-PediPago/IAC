variable "name_prefix" {
  type        = string
  description = "Prefijo project-env"
}

variable "tags" {
  type        = map(string)
  description = "Tags base"
  default     = {}
}
