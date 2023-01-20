/*
라우팅 테이블에 서브넷을 연결.
라우팅에서 경로 설정.
*/

//public
resource "aws_route_table" "public-table" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.tag_name}"
  }

#   route {
#     cidr_block = "10.0.1.0/24"
#     gateway_id = aws_internet_gateway.example.id
#   }

#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
#   }
}

//private