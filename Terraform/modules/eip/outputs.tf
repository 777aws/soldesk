output "eip_id" {
  description = "easdasds"
  value       = aws_eip.lb.id
}
output "public_ip" {
  value = aws_eip.lb.public_ip
}