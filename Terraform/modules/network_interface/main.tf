# eni
resource "aws_network_interface" "test" {
  subnet_id         = var.subnet_id
  security_groups   = [var.security_groups]
  source_dest_check = false
  private_ips       = var.private_ips#["10.2.1.100"]
  
}