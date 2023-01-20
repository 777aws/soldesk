//modules-igw-output
output "igw_id" {
  description = "The name of hq-igw id"
  value = aws_internet_gateway.gw.id
}