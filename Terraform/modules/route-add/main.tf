resource "aws_route" "route-add" {
  route_table_id            = var.route_public_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = var.igw_id
  depends_on                = [var.route_public_id]
#   depends_on                = [aws_route_table.testing]
}