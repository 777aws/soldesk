//sg-output
output "sg_id" {
  description = "sg id outputs"
  value       = aws_security_group.sg.id
}