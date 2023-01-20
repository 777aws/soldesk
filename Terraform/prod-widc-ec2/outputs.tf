output "CGW_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.idc_cgw.id
}


output "eip" {
  description = "eip public ip"
  value       = module.eip.public_ip
}

