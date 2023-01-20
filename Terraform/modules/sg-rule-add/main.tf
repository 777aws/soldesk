resource "aws_security_group_rule" "sg-rule-add" {
  # description = "Security groups rule add"

  type              = var.type
  from_port         = var.from_port
  to_port           = var.to_port
  protocol          = var.protocol
  cidr_blocks       = var.cidr_blocks
  security_group_id = var.security_group_id

  description = "${var.tag_name}-sg-rule"

}
