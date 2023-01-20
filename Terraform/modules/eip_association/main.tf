resource "aws_eip_association" "eip_assoc" {
  # instance_id   = var.instance
  # allocation_id = var.allocation_id
  network_interface_id = var.network_interface
  allocation_id        = var.allocation_id
  
}