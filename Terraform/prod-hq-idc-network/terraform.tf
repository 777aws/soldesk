terraform {
  backend "remote"{
    hostname = "app.terraform.io"
    organization = "22shop"

    workspaces {
      name = "hidc-network-bkkim"
    }
  }
}