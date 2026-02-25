variable "name_prefix" {
  type        = string
  description = "Prefijo project-env"
}

variable "tags" {
  type        = map(string)
  description = "Tags base"
  default     = {}
}

variable "notifications_event_types" {
  type        = list(string)
  description = "Event types que consumirá NotificationsQueue vía filtro SNS->SQS"
  default     = ["ORDER_CREATED", "ORDER_STATUS_UPDATED", "PAYMENT_CREATED"]
}

variable "inventory_event_types" {
  type        = list(string)
  description = "Event types que consumirá InventoryQueue vía filtro SNS->SQS"
  default     = ["ORDER_CREATED"]
}