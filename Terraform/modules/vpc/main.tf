resource "aws_vpc" "vpc-hq" {
    # cidr_block       = "10.3.0.0/16"
    cidr_block       = var.cidr_block
    // instance_tenancy = "default"

    # 인스턴스에 public DNS가 표시되도록 하는 속성
    enable_dns_hostnames = var.public_ip_on
    enable_dns_support   = var.enable_dns_support


    tags = {
        Name = "${var.tag_name}-vpc"
    }
}