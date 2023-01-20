variable "subnet_ids" {
  description = "Subnet id"
  type        = list(any)
}

variable "route_table_id" {
  description = "Subnet id"
  type        = string
}

variable "association_count" {
  description = "Subnet count"
  type        = number
}

