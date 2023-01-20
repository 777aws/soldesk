variable "type" {
  description = "security rule type"
  type  = string
}
variable "from_port" {
  description = "from port"
  type = number
}
variable "to_port" {
  description = "to_port"
  type = number
}
variable "protocol" {
  description = "protocol"
  type = string
}
variable "cidr_blocks" {
  description = "cidr_blocks"
  type = list(string)
}

variable "security_group_id" {
  
}
variable "tag_name" {
  description = "tag_name"
  type  = string
}