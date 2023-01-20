output "ec2_id" {
    value = aws_instance.ubuntu.id
  
}

output "public_ip_associate" {
    value = aws_instance.ubuntu.associate_public_ip_address
  
}

output "sg_id" {
    value = aws_network_interface.eni.security_groups
}