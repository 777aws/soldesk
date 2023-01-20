# resource "aws_vpc_dhcp_options" "" {
#   domain_name          = "service.consul"
#   domain_name_servers  = ["10.2.1.102", "8.8.8.8"]
#   ntp_servers          = ["203.248.240.140"]
# }

resource "aws_vpc_dhcp_options" "dhcp" {
  domain_name          = var.domain_name
  domain_name_servers  = var.domain_name_servers
  ntp_servers          = var.ntp_servers
}