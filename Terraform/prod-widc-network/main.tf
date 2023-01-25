// prod - main
provider "aws" {
  region = "ap-northeast-2"

  #2.x버전의 AWS공급자 허용
  version = "~> 2.0"

}

locals {
  # vpc_id        = data.terraform_remote_state.widc.outputs.vpc_id
  # public_subnet = data.terraform_remote_state.widc.outputs.subnet
  common_tags = {
    project = "22shop-widc-network"
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

// 테라폼클라우드
data "terraform_remote_state" "widc" {
  backend = "remote"

  config = {
    organization = "22shop"

    workspaces = {
      name = "widc-network-bkkim"
    }
  }
}


# module "vpc_widc" {
module "vpc_widc" {
  source = "../modules/vpc"
  tag_name   = "${local.common_tags.project}-vpc"
  cidr_block = "10.2.0.0/16"
  public_ip_on       = false
  enable_dns_support = false

}

module "vpc_igw" {
  source = "../modules/igw"

  vpc_id = module.vpc_widc.vpc_hq_id

  tag_name = "${local.common_tags.project}-vpc-igw"

  depends_on = [
    module.vpc_widc
  ]
}

module "subnet_public" {
  source = "../modules/vpc-subnet"

  vpc_id         = module.vpc_widc.vpc_hq_id
  subnet-az-list = var.subnet-az-public
  public_ip_on   = true
  # vpc_name       = "${local.common_tags.project}-public"
  vpc_name = "${local.common_tags.project}-vpc"
}

// public route
module "route_public" {
  source   = "../modules/route-table"
  tag_name = "${local.common_tags.project}-route_table"
  vpc_id   = module.vpc_widc.vpc_hq_id
}

module "route_igw_add" {
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


module "dhcp_options" {
  source              = "../modules/vpc_dhcp_options"
  domain_name         = "widc.internal"
  domain_name_servers = ["10.2.1.102", "8.8.8.8"]
  ntp_servers         = ["203.248.240.140"]
}
module "dhcp_options_association" {
  source          = "../modules/vpc_dhcp_options_association"
  vpc_id          = module.vpc_widc.vpc_hq_id
  dhcp_options_id = module.dhcp_options.dhcp_id

}

