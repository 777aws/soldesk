resource "aws_eip" "lb" {
  # instance = var.instance
  vpc      = true
  lifecycle {
    create_before_destroy = true
  }
}