variable "name_prefix" {
  type        = string
  description = "Prefijo project-env"
}

variable "tags" {
  type        = map(string)
  description = "Tags base"
  default     = {}
}

############################
# Secret de pagos (JSON)
############################
variable "payments_secret_name" {
  type        = string
  description = "Nombre del secret para credenciales de pagos"
  default     = null
}

variable "payments_secret_description" {
  type        = string
  description = "Descripción del secret"
  default     = "Credenciales de pagos (Stripe/PayPal) + webhook secret"
}

variable "payments_secret_json" {
  type        = string
  description = "JSON con claves de Stripe/PayPal y webhook secret (usar placeholders en repo)"
  default = <<EOT
{
  "stripe_secret_key": "CHANGE_ME",
  "paypal_client_id": "CHANGE_ME",
  "paypal_client_secret": "CHANGE_ME",
  "webhook_secret": "CHANGE_ME"
}
EOT
}
