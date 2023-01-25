// prod - main
provider "aws" {
  region = "ap-northeast-2"

  #2.x버전의 AWS공급자 허용
  version = "~> 3.0"

}

# user data From file 파일에서 불러오기.
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
  // path.module은 root모듈 main 파일에서 module호출시 source에 입력한 경로를 따라감.

  # vars = {
  #     server_port = var.set_ports.http
  #     db_address = data.terraform_remote_state.db.outputs.address
  #     db_port = data.terraform_remote_state.db.outputs.port
  # }
}
# user data From file 파일에서 불러오기.
data "template_file" "dns_user_data" {
  template = file("${path.module}/dns_user-data.sh")
  // path.module은 root모듈 main 파일에서 module호출시 source에 입력한 경로를 따라감.

  # vars = {
  #     server_port = var.set_ports.http
  #     db_address = data.terraform_remote_state.db.outputs.address
  #     db_port = data.terraform_remote_state.db.outputs.port
  # }
}

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
data "aws_caller_identity" "this" {}

locals {
  vpc_id      = data.terraform_remote_state.widc.outputs.vpc_id
  subnet      = data.terraform_remote_state.widc.outputs.subnet
  route_table = data.terraform_remote_state.widc.outputs.route_table
  common_tags = {
    project = "widc-ec2"
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
    dns_port     = 53
    vpn_prot     = 500
    vpn_port-two = 4500
  }
  any_protocol  = "-1"
  tcp_protocol  = "tcp"
  udp_protocol  = "udp"
  icmp_protocol = "icmp"
  all_ips       = ["0.0.0.0/0"]

}


module "route_igw_instance_add" {
  source                 = "../modules/route-add-instance"
  route_public_id        = local.route_table
  destination_cidr_block = "10.0.0.0/8"
  #igw_id          = module.vpc_igw.igw_id
  instance_id = aws_instance.idc_cgw.id
  depends_on  = [aws_instance.idc_cgw]
}

#### 보안그룹
module "instance_sg" {
  source  = "../modules/sg"
  sg_name = "${local.common_tags.project}-sg"
  # vpc_id  = module.vpc_hq.vpc_hq_id
  vpc_id = local.vpc_id
}

module "instance_sg_ingress_tcp" {
  for_each          = local.tcp_port
  source            = "../modules/sg-rule-add"
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
  security_group_id = module.instance_sg.sg_id

  tag_name = each.key
}
module "instance_sg_ingress_udp" {
  for_each          = local.udp_port
  source            = "../modules/sg-rule-add"
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = local.udp_protocol
  cidr_blocks       = local.all_ips
  security_group_id = module.instance_sg.sg_id

  tag_name = each.key
}
module "instance_sg_ingress_icmp" {
  source            = "../modules/sg-rule-add"
  type              = "ingress"
  from_port         = local.any_protocol
  to_port           = local.any_protocol
  protocol          = local.icmp_protocol
  cidr_blocks       = local.all_ips
  security_group_id = module.instance_sg.sg_id

  tag_name = "icmp"
}
module "eks_sg_egress_all" {
  source            = "../modules/sg-rule-add"
  type              = "egress"
  from_port         = local.any_protocol
  to_port           = local.any_protocol
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
  security_group_id = module.instance_sg.sg_id

  tag_name = "egress-all"
}

module "eip" {
  source = "../modules/eip"

}
module "network_interface" {
  source          = "../modules/network_interface"
  subnet_id       = local.subnet.zone-a.id
  security_groups = module.instance_sg.sg_id
  private_ips     = ["10.2.1.100"]

  # instance = aws_instance.idc_cgw.id

}
module "eip_association" {
  source            = "../modules/eip_association"
  network_interface = module.network_interface.network_interface
  allocation_id     = module.eip.eip_id
  depends_on        = [module.eip.eip_id, module.network_interface.network_interface]
}

# resource "aws_instance" "idc_cgw" {
#   ami                    = "ami-035233c9da2fabf52"
#   instance_type          = "t2.micro"
#   key_name               = "default-shop"
#   vpc_security_group_ids = [module.instance_sg.sg_id]

#   subnet_id         = local.subnet.zone-a.id
#   user_data         = data.template_file.user_data.rendered
#   source_dest_check = false
#   tags = {
#     Name = "${local.common_tags.project}-cgw"
#   }
# }
resource "aws_instance" "idc_cgw" {
  ami           = "ami-0c76973fbe0ee100c"
  instance_type = "t2.micro"
  key_name      = "default-shop"
  # vpc_security_group_ids = [module.instance_sg.sg_id]

  user_data = data.template_file.user_data.rendered
  # source_dest_check = false
  tags = {
    Name = "${local.common_tags.project}-cgw"
  }
  network_interface {
    network_interface_id = module.network_interface.network_interface
    device_index         = 0
  }
}

resource "aws_instance" "idc-db" {
  ami                    = "ami-00eb7adeef909470e"
  instance_type          = "t2.micro"
  key_name               = "default-shop"
  vpc_security_group_ids = [module.instance_sg.sg_id]
  subnet_id              = local.subnet.zone-a.id
  private_ip             = "10.2.1.101"
  tags = {
    Name = "${local.common_tags.project}-DB"
  }
}

resource "aws_instance" "idc-dns" {
  ami                    = "ami-04aa5b6de77ecd190"
  instance_type          = "t2.micro"
  key_name               = "default-shop"
  vpc_security_group_ids = [module.instance_sg.sg_id]
  subnet_id              = local.subnet.zone-a.id
  private_ip             = "10.2.1.102"
  user_data              = data.template_file.dns_user_data.rendered
  tags = {
    Name = "${local.common_tags.project}-DNS"
  }
}

