resource "aws_security_group" "sg" {
  description = "Security groups"
  name        = var.sg_name
  vpc_id = var.vpc_id

}
