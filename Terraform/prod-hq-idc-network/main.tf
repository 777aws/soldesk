// prod - main
provider "aws" {
  region = "ap-northeast-2"

  #2.x버전의 AWS공급자 허용
  version = "~> 3.0"

}

locals {
  region = "ap-northeast-2"
  common_tags = {
    project = "22shop-hq-idc"
    owner   = "bkkim"
  }
 
  tcp_port = {
    any_port    = 0
    http_port   = 80
    https_port  = 443
    ssh_port    = 22
    dns_port    = 53
    django_port = 8000
    mysql_port  = 3306
    nfs_port = 2049
  }
  udp_port = {
    dns_port = 53
  }
  any_protocol  = "-1"
  tcp_protocol  = "tcp"
  icmp_protocol = "icmp"
  all_ips       = ["0.0.0.0/0"]
}

// GET 계정정보
data "aws_caller_identity" "this" {}

// eks를 위한 iam역할 생성 데이터 조회
# data "aws_iam_policy_document" "eks-assume-role-policy" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["eks.amazonaws.com"]
#     }
#   }
# }


module "vpc_idc" {
  source = "../modules/vpc"
  #   source = "github.com/Seong-dong/team_prj/tree/main/modules/vpc"
  tag_name   = "${local.common_tags.project}-vpc"
  cidr_block = "10.4.0.0/16"
  public_ip_on       = true
  enable_dns_support = true
}

module "vpc_igw" {
  source = "../modules/igw"

  vpc_id = module.vpc_idc.vpc_hq_id

  tag_name = "${local.common_tags.project}-vpc_igw"

  depends_on = [
    module.vpc_idc
  ]
}

module "subnet_public" {
  source = "../modules/vpc-subnet"

  vpc_id         = module.vpc_idc.vpc_hq_id
  # subnet-az-list = var.subnet-az-public
  subnet-az-list = {
    "zone-a" = {
      name = "${local.region}a"
      cidr = "10.4.1.0/24"
    }
    # "zone-c" = {
    #   name = "${local.region}c"
    #   cidr = local.cidr.zone_c
    # }
  }
  public_ip_on   = false
  # vpc_name       = "${local.common_tags.project}-public"
  #alb-ingress 생성을 위해 지정
  vpc_name = "${local.common_tags.project}-vpc"
}

// public route
module "route_public" {
  source   = "../modules/route-table"
  tag_name = "${local.common_tags.project}-route_table"
  vpc_id   = module.vpc_idc.vpc_hq_id

}

module "route_add" {
  source          = "../modules/route-add"
  route_public_id = module.route_public.route_id
  igw_id          = module.vpc_igw.igw_id
}

module "route_association" {
  source         = "../modules/route-association"
  route_table_id = module.route_public.route_id

  association_count = 1
  subnet_ids        = [module.subnet_public.subnet.zone-a.id]
}




# // private subnet
module "subnet_private" {
  source = "../modules/vpc-subnet"

  vpc_id         = module.vpc_idc.vpc_hq_id
  subnet-az-list = var.subnet-az-private
  public_ip_on   = false
  # vpc_name       = "${local.common_tags.project}-public"
  #alb-ingress 생성을 위해 지정
  vpc_name = "${local.common_tags.project}-vpc"
}


// private route
module "route_private" {
  source   = "../modules/route-table"
  tag_name = "${local.common_tags.project}-private_route_table"
  vpc_id   = module.vpc_idc.vpc_hq_id

}

module "private_route_association" {
  source         = "../modules/route-association"
  route_table_id = module.route_private.route_id

  association_count = 2
  subnet_ids        = [module.subnet_private.subnet.zone-a.id, module.subnet_private.subnet.zone-c.id]
}
