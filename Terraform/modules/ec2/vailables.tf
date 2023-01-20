variable "ami_name" {
  description = "ami name"
  type        = string
}

variable "instance_type" {
  type = string
}

variable "tag_name" {
  type = string
}

variable "public_ip_associate" {
  type = bool
}
variable "key_name" {
  type = string
}
# variable "subnet_id" {
#   type = string
# }

variable "public_subnet" {
  type = string
}

variable "private_subnet" {
  type = string
}

variable "sg_list" {
  description = "sg list"
  type = list(string)
  
}