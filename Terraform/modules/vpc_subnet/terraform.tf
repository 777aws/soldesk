terraform {
  backend "remote"{
    hostname = "app.terraform.io"
    organization = "33shop"

    workspaces {
      name = "tf-cloud-backend"
    }
  }
}