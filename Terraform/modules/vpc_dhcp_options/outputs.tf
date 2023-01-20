
output "dhcp_id" {
  description = "The id of vpc dhcp options id"
  value = aws_vpc_dhcp_options.dhcp.id
}
