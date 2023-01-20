variable "vpc_id" {
    description = "set vpc id"
    type = string
}

variable "vpc_name" {
    description = "set vpc name"
    type = string
}
// reference | https://github.com/davidcsi/terraform/blob/master/healthchecks/main.tf
variable "subnet-az-list" {
    description = "Subnet available zone & cidr"
    type = map(map(string))
    # default = {
    #     "zone-a" = {
    #         name = "ap-northeast-2a"
    #         cidr = "10.3.1.0/24"
    #     }
    #     "zone-b" = {
    #         name = "ap-northeast-2b"
    #         cidr = "10.3.2.0/24"
    #     }
    #     "zone-c" = {
    #         name = "ap-northeast-2c"
    #         cidr = "10.3.3.0/24"
    #     }
    #     "zone-d" = {
    #         name = "ap-northeast-2d"
    #         cidr = "10.3.4.0/24"
    #     }
    # }
}

variable "public_ip_on" {
  type = bool
}

# variable "k8s_ingress" {
#   type = bool
# }