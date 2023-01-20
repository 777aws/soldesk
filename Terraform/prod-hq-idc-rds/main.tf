// prod - main
provider "aws" {
  region = "ap-northeast-2"

  #2.x버전의 AWS공급자 허용
  version = "~> 3.0"

}

locals {
  vpc_id        = data.terraform_remote_state.hq_vpc_id.outputs.vpc_id
  public_subnet = data.terraform_remote_state.hq_vpc_id.outputs.subnet
  region = "ap-northeast-2"
  common_tags = {
    project = "22shop-hq-idc-rds"
    owner   = "icurfer"
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
// 테라폼클라우드
data "terraform_remote_state" "hq_vpc_id" {
  backend = "remote"

  config = {
    organization = "icurfer" // 초기 설정값

    workspaces = {
      name = "tf-22shop-idc-network"
    }
  }
}

// 보안그룹 생성
module "rds_sg" {
  source  = "../modules/sg"
  sg_name = "${local.common_tags.project}-sg"
  vpc_id = local.vpc_id
}

module "rds_sg_ingress_sql" {
  source            = "../modules/sg-rule-add"
  type              = "ingress"
  from_port         = local.mysql_port
  to_port           = local.mysql_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
  security_group_id = module.rds_sg.sg_id

  tag_name = each.key
}

module "rds_sg_egress_all" {
  source            = "../modules/sg-rule-add"
  type              = "egress"
  from_port         = local.any_protocol
  to_port           = local.any_protocol
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
  security_group_id = module.efs_sg.sg_id

  tag_name = "egress-all"
}

























