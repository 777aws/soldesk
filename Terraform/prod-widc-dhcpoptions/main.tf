provider "aws" {
  region = "ap-northeast-2"

  #2.x버전의 AWS공급자 허용
  version = "~> 3.0"

}



locals {
  vpc_id        = data.terraform_remote_state.widc.outputs.vpc_id
  public_subnet = data.terraform_remote_state.widc.outputs.subnet
  common_tags = {
    project = "22shop"
    owner   = "icurfer"

  }
  tcp_port = {
    # any_port    = 0
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

  node_group_scaling_config = {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }
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

module "dhcp_options" {
  source              = "../modules/vpc_dhcp_options"
  domain_name         = "widc.internal"
  domain_name_servers = ["10.2.1.102", "8.8.8.8"]
  ntp_servers         = ["203.248.240.140"]
}
module "dhcp_options_association" {
  source          = "../modules/vpc_dhcp_options_association"
  vpc_id          = local.vpc_id
  dhcp_options_id = module.dhcp_options.dhcp_id

}
