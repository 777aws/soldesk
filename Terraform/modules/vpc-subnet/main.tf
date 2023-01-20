resource "aws_subnet" "subnets" {
    vpc_id     = var.vpc_id
    # module.vpc_hq.vpc_hq_id
    
    for_each = var.subnet-az-list
    availability_zone = each.value.name
    cidr_block = each.value.cidr

    map_public_ip_on_launch = var.public_ip_on ? true : false
    
    tags = {
    Name = var.vpc_name
    #"kubernetes.io/role/elb" = "${var.k8s_ingress ? 1 : 0}"
    # Name = module.vpc_hq.vpcHq.id
    }
}