variable "domain_name" {
    description = "set domain_name"
    type = string
}

variable "domain_name_servers" {
    description = "set domain_name_servers"
    type = list(string)
}
variable "ntp_servers" {
    description = "set ntp_servers"
    type = list(string)
}