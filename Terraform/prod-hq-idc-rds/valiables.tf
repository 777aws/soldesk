# variable "cidr_block" {
#     type = string
#     default = "10.3.0.0/16"

# }

variable "prod_name" {
  description = "value"
  type        = string
  default     = "22shop"
}

# variable "igw_id" {
#     description = "value"
#     type = string
# }

variable "subnet-az-public" {
  description = "Subnet available zone & cidr"
  type        = map(map(string))
  default = {
    "zone-a" = {
      name = "ap-northeast-2a"
      cidr = "10.4.1.0/24"
    }
    "zone-c" = {
      name = "ap-northeast-2c"
      cidr = "10.4.3.0/24"
    }
  }
}
variable "subnet-az-private" {
  description = "Subnet available zone & cidr"
  type        = map(map(string))
  default = {
    "zone-b" = {
      name = "ap-northeast-2b"
      cidr = "10.4.2.0/24"
    }
    "zone-d" = {
      name = "ap-northeast-2d"
      cidr = "10.4.4.0/24"
    }
  }
}