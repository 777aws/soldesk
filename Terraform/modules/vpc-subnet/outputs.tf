//modules-subnet-outputs
output "subnet" {
  description = "The name of vpc hq id"
  value = aws_subnet.subnets
}