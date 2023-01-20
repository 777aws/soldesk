//라우팅 테이블 서브넷 연결
resource "aws_route_table_association" "route-association" {
    # for_each = toset(var.subnet_ids)
    # subnet_id      = each.value
    count = var.association_count
    subnet_id = var.subnet_ids[count.index]
    route_table_id = var.route_table_id
    
    
}