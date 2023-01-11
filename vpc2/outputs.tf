//main-outputs
output "aws_id" {
  description = "The AWS Account ID."
  value       = data.aws_caller_identity.this.account_id
}

output "subnet" {
  description = "The name of vpc hq id"
  value       = aws_subnet.vpc_idc_1a
}

output "vpc_id" {
  description = "vpc_id"
  value = aws_vpc.vpc_idc
  
}
