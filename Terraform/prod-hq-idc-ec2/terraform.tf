terraform {
  backend "remote"{
    hostname = "app.terraform.io"
    organization = "22shop"

    workspaces {
      name = "hq-idc-ec2-bkkim"
    }
  }
}