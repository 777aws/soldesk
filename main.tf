# terraform {
#   backend "s3" {
#     bucket = "777aws"
#     key = "webservice/terraform.tfstate"
#     region = "ap-northeast-2"
#     dynamodb_table = "777aws-locked"
#     encrypt = true
#   }
# }

provider "aws" {
  region = "ap-northeast-2"
  # 2.x 버전의 AWS 공급자 허용
  version = "~> 2.0"
}

# VPC 생성
resource "aws_vpc" "VPC_HQ" {
  cidr_block       = "10.3.0.0/16"
  #instance_tenancy = "default"

  # 인스턴스에 public DNS가 표시되도록 하는 속성
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = tomap({
    "Name"                                      = "terraform-eks-demo-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

# HQ Public 서브넷 생성
resource "aws_subnet" "VPC_HQ_public_1a" {
  vpc_id            = aws_vpc.VPC_HQ.id
  cidr_block        = "10.3.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = tomap({
    "Name"                                      = "terraform-eks-demo-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}
resource "aws_subnet" "VPC_HQ_public_1c" {
  vpc_id            = aws_vpc.VPC_HQ.id
  cidr_block        = "10.3.2.0/24"
  availability_zone = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = tomap({
    "Name"                                      = "terraform-eks-demo-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

# 인터넷 게이트웨이 생성 후 VPC-HQ에 연결
resource "aws_internet_gateway" "VPC_HQ_IGW" {
  vpc_id = aws_vpc.VPC_HQ.id

  tags   = {
    Name = "VPC_HQ_IGW"
  }
}

# HQ 라우팅 테이블 생성 후 igw에 연결
resource "aws_route_table" "VPC_HQ_RT" {
  vpc_id = aws_vpc.VPC_HQ.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_HQ_IGW.id
  }
  tags  = {
    Name = "VPC_HQ_RT"
  }
}


# 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "VPC_HQ_public_1a" {
  subnet_id      = aws_subnet.VPC_HQ_public_1a.id
  route_table_id = aws_route_table.VPC_HQ_RT.id
}
resource "aws_route_table_association" "VPC_HQ_public_1c" {
  subnet_id      = aws_subnet.VPC_HQ_public_1c.id
  route_table_id = aws_route_table.VPC_HQ_RT.id
}



# 보안그룹 생성 8080포트 허용
resource "aws_security_group" "instance" {
  name        = "${var.cluster_name}-web-instance"
  description = "Allow all HTTP"
  vpc_id      = aws_vpc.VPC_HQ.id

}
resource "aws_security_group_rule" "allow_sever_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = local.tcp_protocol #"tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port         = "22"
  to_port           = "22"
  protocol          = local.tcp_protocol #"tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_ICMP_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port         = "-1"
  to_port           = "-1"
  protocol          = "ICMP"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_sever_outbound" {
  type = "egress"
  security_group_id = aws_security_group.instance.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

# alb 보안그룹
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb"
  description = "Allow all HTTP"
  vpc_id      = aws_vpc.VPC_HQ.id

}
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
}
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
}

# instance
resource "aws_instance" "testEC201" {
  ami                    = "ami-035233c9da2fabf52"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [ 
    aws_security_group.instance.id
   ]
  subnet_id                   = aws_subnet.VPC_HQ_public_1a.id
  associate_public_ip_address = "true"
  key_name                    = "soldesk"
  user_data = <<-EOF
  #!/bin/bash
  hostname ELB-EC2-1
  yum install httpd -y
  yum install net-snmp net-snmp-utils -y
  yum install tcpdump -y
  service httpd start
  chkconfig httpd on
  service snmpd start
  chkconfig snmpd on
  echo "<h1>ELB-EC2-1 Web Server</h1>" > /var/www/html/index.html

  EOF

  tags = {
    "Name" = "VPC_HQ_public_ec2-1"
  }
}
resource "aws_instance" "testEC202" {
  ami                         = "ami-035233c9da2fabf52"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [ 
    aws_security_group.instance.id
   ]
  subnet_id                   = aws_subnet.VPC_HQ_public_1c.id
  associate_public_ip_address = "true"
  key_name               = "soldesk"
  user_data = <<-EOF
  #!/bin/bash
  hostname ELB-EC2-1
  yum install httpd -y
  yum install net-snmp net-snmp-utils -y
  yum install tcpdump -y
  service httpd start
  chkconfig httpd on
  service snmpd start
  chkconfig snmpd on
  echo "<h1>ELB-EC2-2 Web Server222</h1>" > /var/www/html/index.html

  EOF

  tags = {
    "Name" = "VPC_HQ_public_ec2-2"
  }
}

# ALB
resource "aws_alb" "test" {
  name                             = "test-alb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [ aws_security_group.alb.id ]
  subnets                          = [ aws_subnet.VPC_HQ_public_1a.id , aws_subnet.VPC_HQ_public_1c.id ]
  enable_cross_zone_load_balancing = true
}
resource "aws_alb_target_group" "test" {
  name     = "tset-alb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.VPC_HQ.id
  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
    interval = 15
    timeout  = 3
    healthy_threshold =2
    unhealthy_threshold =2
  }
}
resource "aws_alb_target_group_attachment" "privateInstance01" {
  target_group_arn = aws_alb_target_group.test.arn
  target_id = aws_instance.testEC201.id
  port = 80
}
resource "aws_alb_target_group_attachment" "privateInstance02" {
  target_group_arn = aws_alb_target_group.test.arn
  target_id = aws_instance.testEC202.id
  port = 80
}
resource "aws_alb_listener" "test" {
  load_balancer_arn = aws_alb.test.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.test.arn
  }
}

# Route53 생성
resource "aws_route53_zone" "primary" {
  name = "777aws.ml"
  comment = "777aws.ml"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "777aws.ml"
  type    = "A"
  alias {
    name     = "${aws_alb.test.dns_name}"
    zone_id  = "${aws_alb.test.zone_id}"
    evaluate_target_health = true
  }
}


resource "aws_wafv2_web_acl" "external" {
  name  = "ExternalACL"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWS-AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "ExternalACL"
    sampled_requests_enabled   = false
  }

}

resource "aws_wafv2_web_acl_association" "waf_alb" {
  resource_arn = "${aws_alb.test.arn}"
  web_acl_arn  = "${aws_wafv2_web_acl.external.arn}"
}

###################################################
############################################
#########################
# EKS
# 역할 생성
resource "aws_iam_role" "demo-cluster" {
  name = "terraform-eks-demo-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
# 정책을 역할에 부착
resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.demo-cluster.name
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.demo-cluster.name
}

# 보안그룹
resource "aws_security_group" "demo-cluster" {
  name = "${var.cluster_name}-eks-demo-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id = aws_vpc.VPC_HQ.id
}
resource "aws_security_group_rule" "demo-cluster-ingress-workstation-http" {
  type = "ingress"
  security_group_id = aws_security_group.demo-cluster.id

  from_port = var.server_port
  to_port = var.server_port
  protocol = local.tcp_protocol #"tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "demo-cluster-ingress-workstation-https" {
  type = "ingress"
  security_group_id = aws_security_group.demo-cluster.id

  from_port = "443"
  to_port = "443"
  protocol = local.tcp_protocol #"tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "demo-cluster-ingress-workstation-ICMP" {
  type = "ingress"
  security_group_id = aws_security_group.demo-cluster.id

  from_port = "-1"
  to_port = "-1"
  protocol = "ICMP"
  cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "demo-cluster-ingress-workstation-outbound" {
  type = "egress"
  security_group_id = aws_security_group.demo-cluster.id

  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_eks_cluster" "demo" {
  name     = var.cluster-name
  role_arn = aws_iam_role.demo-cluster.arn

##   enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    security_group_ids = [aws_security_group.demo-cluster.id]
    subnet_ids         = [
                          aws_subnet.VPC_HQ_public_1a.id,
                          aws_subnet.VPC_HQ_public_1c.id
                          ]
    endpoint_private_access = true
    endpoint_public_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.demo-cluster-AmazonEKSVPCResourceController,
  ]
#   output "endpoint" {
#   value = aws_eks_cluster.example.endpoint
# }

# output "kubeconfig-certificate-authority-data" {
#   value = aws_eks_cluster.example.certificate_authority[0].data
# }

}

##################################
###########################################
######################################
### EKS-nodes ##########
# 역할 생성
resource "aws_iam_role" "demo-node" {
  name = "terraform-eks-demo-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
# 정책을 역할에 부착
resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.demo-node.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.demo-node.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.demo-node.name
}

resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "demo"
  node_role_arn   = aws_iam_role.demo-node.arn
  subnet_ids      = [
                      aws_subnet.VPC_HQ_public_1a.id,
                      aws_subnet.VPC_HQ_public_1c.id
                      ]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.demo-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}




























###########################################################

resource "aws_vpc" "VPC_DTC" {
  cidr_block           = "10.4.0.0/16"
  #instance_tenancy = "default"

  # 인스턴스에 public DNS가 표시되도록 하는 속성
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC_DTC"
  }
}
# DTC Public 서브넷 생성
resource "aws_subnet" "VPC_DTC_public_1a" {
  vpc_id            = aws_vpc.VPC_DTC.id
  cidr_block        = "10.4.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "VPC_DTC_public_1A"
  }
}
resource "aws_subnet" "VPC_DTC_public_1c" {
  vpc_id            = aws_vpc.VPC_DTC.id
  cidr_block        = "10.4.2.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "VPC_DTC_public_1C"
  }
}
# DTC Private 서브넷 생성 EC2, RDS용
resource "aws_subnet" "VPC_DTC_private_1a" {
  vpc_id            = aws_vpc.VPC_DTC.id
  cidr_block        = "10.4.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "VPC_DTC_private_1A"
  }
}
resource "aws_subnet" "VPC_DTC_private_1c" {
  vpc_id            = aws_vpc.VPC_DTC.id
  cidr_block        = "10.4.4.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "VPC_DTC_private_1C"
  }
}
# 인터넷 게이트웨이 생성 후 VPC-DTC에 연결
resource "aws_internet_gateway" "VPC_DTC_IGW" {
  vpc_id = aws_vpc.VPC_DTC.id

  tags = {
    Name = "VPC_DTC_IGW"
  }
}
# DTC 라우팅 테이블 생성 후 igw에 연결
resource "aws_route_table" "VPC_DTC_RT" {
  vpc_id = aws_vpc.VPC_DTC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_DTC_IGW.id
  }
  tags = {
    Name = "VPC_DTC_RT"
  }
}
# DTC Private Table 은 igw 연결 X
resource "aws_route_table" "VPC_DTC_private_RT" {
  vpc_id = aws_vpc.VPC_DTC.id
  tags = {
    Name = "VPC_DTC_private_RT"
  }
}
resource "aws_route_table_association" "VPC_DTC_public_1a" {
  subnet_id      = aws_subnet.VPC_DTC_public_1a.id
  route_table_id = aws_route_table.VPC_DTC_RT.id
}
resource "aws_route_table_association" "VPC_DTC_public_1c" {
  subnet_id      = aws_subnet.VPC_DTC_public_1c.id
  route_table_id = aws_route_table.VPC_DTC_RT.id
}
resource "aws_route_table_association" "VPC_DTC_private_1a" {
  subnet_id      = aws_subnet.VPC_DTC_private_1a.id
  route_table_id = aws_route_table.VPC_DTC_private_RT.id
}
resource "aws_route_table_association" "VPC_DTC_private_1c" {
  subnet_id      = aws_subnet.VPC_DTC_private_1c.id
  route_table_id = aws_route_table.VPC_DTC_private_RT.id
}


# VPC-DTC 에 NAT를 생성한다.
# NAT를 생성하기 위해선 EIP(Elastic IP Address)가 필요하다.
# NAT는 private 서브넷을 위한것
# NAT는 private 서브넷을 위한것이지만 NAT 자체는 public 서브넷에 설정
# resource "aws_eip" "DTC_nat" {
#   vpc = true 
# }
# resource "aws_nat_gateway" "DTC" {
#   allocation_id = aws_eip.DTC_nat.id
#   subnet_id     = aws_subnet.VPC_DTC_private_1a.id
# }
# # Private 서브넷이 지정된 route table에 NAT를 지정해준다.
# resource "aws_route" "VPC_DTC_private"{
#   route_table_id         = aws_route_table.VPC_DTC_private_RT.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.DTC.id
# }


# 보안그룹
# Public 보안그룹
## 퍼블릭 보안 그룹
resource "aws_security_group" "DTC_PublicSG" {
  vpc_id = aws_vpc.VPC_DTC.id
  name   = "DTC_PublicSG"

}
## 프라이빗 보안 그룹
resource "aws_security_group" "DTC_PrivateSG" {
  vpc_id = aws_vpc.VPC_DTC.id
  name   = "DTC_private SG"
}


## 퍼블릭 보안 그룹 규칙
resource "aws_security_group_rule" "DTC_PublicSG_HTTPingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.DTC_PublicSG.id
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group_rule" "DTC_PublicSG_HTTPSingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.DTC_PublicSG.id
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group_rule" "DTC_PublicSG_SSHingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.DTC_PublicSG.id
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group_rule" "DTC_PublicSG_HTTPegress" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.DTC_PublicSG.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "DTC_PublicSG_HTTPSegress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.DTC_PublicSG.id
  lifecycle {
    create_before_destroy = true
  }
}
### Private Security Group rules
resource "aws_security_group_rule" "DTC_PrivateSG_RDSingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.DTC_PrivateSG.id
  source_security_group_id = aws_security_group.DTC_PublicSG.id
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group_rule" "DTC_PrivateSG_RDSegress" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "TCP"
  security_group_id        = aws_security_group.DTC_PrivateSG.id
  source_security_group_id = aws_security_group.DTC_PublicSG.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "DTC_PublicSG_SSHegress" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.DTC_PublicSG.id
  lifecycle {
    create_before_destroy = true
  }
}


##############################################################
# RDS생성전에 서브넷 그룹 생성
# 이것이 없으면 Terraform은 기본 VPC에 RDS 인스턴스를 생성합니다.
resource "aws_db_subnet_group" "test" {
  name       = "test"
  subnet_ids = [aws_subnet.VPC_DTC_private_1a.id, aws_subnet.VPC_DTC_private_1c.id ]

  tags = {
    Name = "test"
  }
}

# RDS 생성
resource "aws_db_instance" "test_rds" {
  identifier_prefix      = "prod-mysql" # 고유 식별자
  engine                 = "MariaDB"
  # MariaDB version 수정해야함
  engine_version         = "10.6.10"
  allocated_storage      = 10
  instance_class         = "db.t2.small"

  name                   = "testDB"
  username               = "admin"

  password               = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"] #var.db_password 
  db_subnet_group_name   = aws_db_subnet_group.test.name
  vpc_security_group_ids = [aws_security_group.DTC_PrivateSG.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "mysql/admin/soldesk"
}

#################################
# EFS ##
# EFS 탑재 대상에 연결할 보안 그룹을 생성
resource "aws_security_group" "efs_sg" {
  name        = "efs_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.VPC_DTC.id

}

resource "aws_security_group_rule" "DTC_EFSingress" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs_sg.id

}
resource "aws_security_group_rule" "DTC_EFSegress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs_sg.id
}

# EFS 파일 시스템 생성
resource "aws_efs_file_system" "efs" {
  # 원존 클래스를 이용할 경우
  # availability_zone_name = "ap-northeast-2a"

  # 유휴 시 데이터 암호화
  encrypted        = true
  # KMS에서 관리형 키를 이용하려면 kms_key_id 속성을 붙여줍니다.

  # 성능 모드: generalPurpose(범용 모드), maxIO(최대 IO 모드)
  performance_mode = "generalPurpose"

  # 버스팅 처리량 모드
  throughput_mode  = "bursting"

  # 프로비저닝 처리량 모드
  # throughput_mode = "provisioned"
  # provisioned_throughput_in_mibps = 100

  # 수명 주기 관리
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

## 탑재 대상을 수동으로 생성해줍니다.
### AWS 콘솔에서 작업하면 이러한 탑재 대상을 
#### 표준 클래스의 경우 모든 가용 영역에 자동으로 생성해주지만,
#### 테라폼을 이용하게 되면 모두 수동으로 생성해주어야 합니다.
#### 탑재 대상에 2049번 포트를 허용하는 보안 그룹을 연결합니다.
# 표준 클래스로 EFS를 생성하더라도 탑재 대상은 모든 가용영역에 수동으로 지정해주어야 합니다. 
resource "aws_efs_mount_target" "mount" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.VPC_DTC_public_1a.id

  security_groups = [aws_security_group.efs_sg.id]
}
# NFS 마운트 기본 인스턴스 생성
# userdata 인스턴스 생성후 마운트 폴더를 생성하고,
## EFS 파일 시스템을 마운트하는 작업
## 의존성 depends_on 추가
resource "aws_instance" "test_ec2" {
  ami                         = "ami-035233c9da2fabf52"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.DTC_PublicSG.id]
  subnet_id                   = aws_subnet.VPC_DTC_public_1a.id
  associate_public_ip_address = "true"
  key_name                    = "soldesk"
  user_data                   = <<EOF
  #!/bin/bash
  sudo mkdir -p mnt
  sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.efs.dns_name}:/ mnt
  EOF
  depends_on = [
    aws_efs_mount_target.mount
  ]
  tags = {
    "Name" = "nfs-testinstance"
  }
}







































# # HTTPS 사용할시
# # aws_alb_listener는 HTTP와 HTTPS를 각각 따로 설정
# # data "aws_acm_certificate" "example_dot_com"   { 
# #   domain   = "*.example.com."
# #   statuses = ["ISSUED"]
# # }

# # resource "aws_alb_listener" "https" {
# #   load_balancer_arn = "${aws_alb.frontend.arn}"
# #   port              = "443"
# #   protocol          = "HTTPS"
# #   ssl_policy        = "ELBSecurityPolicy-2016-08"
# #   certificate_arn   = "${data.aws_acm_certificate.example_dot_com.arn}"

# #   default_action {
# #     target_group_arn = "${aws_alb_target_group.frontend.arn}"
# #     type             = "forward"
# #   }
# # }





locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}
####################
###################
############