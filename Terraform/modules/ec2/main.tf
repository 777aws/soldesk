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

resource "aws_network_interface" "eni" {
  subnet_id = var.public_ip_associate ? var.public_subnet : var.private_subnet
  # private_ips = ["172.16.10.100"]
  security_groups = var.sg_list
  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "ubuntu" {
  ami = var.ami_name
  # "ami-0ab04b3ccbadfae1f"
  instance_type = var.instance_type
  # "t2.micro"

  tags = {
    Name = "${var.tag_name}"
  }

  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
    # delete_on_termination = true
    
    # security_groups = var.sg_list
    
  }
  
  key_name = var.key_name

  user_data = data.template_file.user_data.rendered

  # lifecycle{
  #       create_before_destroy = true
  # } #생성 후 삭제
}

