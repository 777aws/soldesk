//main-outputs
output "aws_id" {
  description = "The AWS Account ID."
  value       = data.aws_caller_identity.this.account_id
}

output "subnet" {
  description = "The name of vpc hq id"
  value       = module.subnet_public.subnet
}

output "vpc_id" {
  description = "vpc_id"
  value = module.vpc_idc.vpc_hq_id
}
output "private_subnet" {
  description = "The name of vpc hq id"
  value       = module.subnet_private.subnet
}

output "route_public_id" {
  description = "get private route id"
  value = module.route_public.route_id
}
output "route_private_id" {
  description = "get private route id"
  value = module.route_private.route_id
}