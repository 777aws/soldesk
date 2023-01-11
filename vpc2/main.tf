
provider "aws" {
  region = "ap-northeast-2"
  # 2.x 버전의 AWS 공급자 허용
  version = "~> 3.0"
}



locals {
  region = "ap-northeast-2"
  common_tags = {
    project = "22shop-web-idc"
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
    nfs_port    = 2049
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


# vpc 생성
resource "aws_vpc" "vpc_idc" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${local.common_tags.project}-vpc"
  }
}


# IGW 인터넷 게이트웨이 생성 후 VPC에 연결
resource "aws_internet_gateway" "vpc_idc_igw" {
  vpc_id = aws_vpc.vpc_idc.id
  tags = {
    Name = "${local.common_tags.project}-vpc_igw"
  }

}

# resource "aws_internet_gateway_attachment" "igw_attach" {
#   vpc_id              = aws_vpc.VPC_GeC_IDC.id
#   internet_gateway_id = aws_internet_gateway.VPC_GeC_IDC_IGW
# }

# 서브넷
resource "aws_subnet" "vpc_idc_1a" {
  vpc_id                  = aws_vpc.vpc_idc.id
  cidr_block              = "10.2.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.common_tags.project}-vpc_subnet"
  }
}

# RT
resource "aws_route_table" "vpc_idc_rt" {
  vpc_id = aws_vpc.vpc_idc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_idc_igw.id
  }
  tags = {
    Name = "${local.common_tags.project}-vpc_rt"
  }
}
# 라우트 테이블 서브넷 연결
resource "aws_route_table_association" "IDCSubnetRTAssociation" {
  subnet_id      = aws_subnet.vpc_idc_1a.id
  route_table_id = aws_route_table.vpc_idc_rt.id
}

#
resource "aws_route" "idc_route" {
  route_table_id         = aws_route_table.vpc_idc_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_idc_igw.id
  depends_on             = [aws_internet_gateway.vpc_idc_igw]
}




# cgw route
resource "aws_route" "idc_cgw_route" {
  route_table_id         = aws_route_table.vpc_idc_rt.id
  destination_cidr_block = "10.0.0.0/8"
  instance_id            = aws_instance.idc_cgw.id
  depends_on             = [aws_instance.idc_cgw]
}





#보안그룹
resource "aws_security_group" "sg" {
  description = "aws_security_group"
  name        = "idc-sg"
  vpc_id      = aws_vpc.vpc_idc.id
}

# 보안그룹 룰s
resource "aws_security_group_rule" "allow_sever_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = "22"
  to_port           = "22"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_icmp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "ICMP"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_dns_tcp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = "53"
  to_port           = "53"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_dns_udp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = "53"
  to_port           = "53"
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_dns_udp_vpn1_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = "500"
  to_port           = "500"
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_dns_udp_vpn2_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = "4500"
  to_port           = "4500"
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = "443"
  to_port           = "443"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}






# 인스턴스
# Create a instance cgw
resource "aws_instance" "idc_cgw" {
  ami                    = "ami-035233c9da2fabf52"
  instance_type          = "t2.micro"
  key_name               = "default-shop"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.vpc_idc_1a.id
  user_data = <<-EOF
  #!/bin/bash
(
echo "p@ssw0rd"
echo "p@ssw0rd"
) | passwd --stdin root
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
service sshd restart
hostnamectl --static set-hostname IDC-SEOUL-CGW
yum -y install tcpdump openswan
cat <<EOF>> /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects =


EOF

  tags = {
    Name = "${local.common_tags.project}-cgw"
  }
}

resource "aws_instance" "idc-db" {
  ami                    = "ami-035233c9da2fabf52"
  instance_type          = "t2.micro"
  key_name               = "default-shop"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.vpc_idc_1a.id
  tags = {
    Name = "${local.common_tags.project}-DB"
  }
}

resource "aws_instance" "idc-dns" {
  ami                    = "ami-035233c9da2fabf52"
  instance_type          = "t2.micro"
  key_name               = "default-shop"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.vpc_idc_1a.id
  tags = {
    Name = "${local.common_tags.project}-DNS"
  }
}







# eni
resource "aws_network_interface" "test" {
  subnet_id         = aws_subnet.vpc_idc_1a.id
  private_ips       = ["10.2.1.100"]
  security_groups   = [aws_security_group.sg.id]
  source_dest_check = false

  attachment {
    instance     = aws_instance.idc_cgw.id
    device_index = 1
  }
}

resource "aws_eip" "lb" {
  instance = aws_instance.idc_cgw.id
  vpc      = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.idc_cgw.id
  allocation_id = aws_eip.lb.id
}
