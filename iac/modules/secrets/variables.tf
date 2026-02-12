variable "name_prefix" {
  type        = string
  description = "Prefijo project-env (ej: pedidos-pagos-dev)"
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable "payments_secret_name" {
  type        = string
  description = "Nombre del secret para pagos"
  default     = null
}

variable "payments_secret_description" {
  type        = string
  description = "Descripción del secret"
  default     = "Credenciales y secretos de pasarela de pagos (Stripe/PayPal) + webhook secret"
}

variable "payments_secret_json" {
  type        = string
  description = "JSON string con keys placeholder"
  default     = "{\"stripe_api_key\":\"CHANGE_ME\",\"paypal_client_id\":\"CHANGE_ME\",\"paypal_secret\":\"CHANGE_ME\",\"webhook_secret\":\"CHANGE_ME\"}"
}
