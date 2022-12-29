# # variable "db_remote_state_bucket" {
# #   description = "The name of the S3 bucket used for the database's remote state storage"
# #   type = string
# #   default = "777aws"
# # }

# # variable "db_remote_state_key" {
# #   description = "The name of the key in the S3 bucket used for the database's remote state storage"
# #   type = string
# #   default = "global/terraform.tfstate"
# # }

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 80
}
variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type = string
  default = "webserver-prod"
}
# # variable "db_remote_state_bucket" {
# #   description = "The name of the S3 bucket for the database's remote state"
# #   type = string
# # }
# variable "db_remote_state_key" {
#   description = "The path for the database's remote state in S3"
#   type = string
# }
# variable "instance_type" {
#   description = "The type of EC2 Instances to run (e.g. t2.micro)"
#   type = string
# }
# variable "desired_capacity" {
#   description = "The desired capacity of ec2 Instance to run"
#   type = number
# }
# variable "min_size" {
#   description = "The minimum number of EC2 Instances in the ASG"
#   type = number
# }
# variable "max_size" {
#   description = "The maximum number of EC2 Instances in the ASG"
#   type = number
# }

# variable "custom_tags" {
#   description = "Custom tags to set on the Instances in the ASG"
#   type        = map(string)
#   default     = {}
# }

# variable "enable_autoscalling" {
#   description = "If set to ture, enable auto scaling"
#   type = bool
# }



########################
#################################
############################
#####################
variable "cluster-name" {
  default = "terraform-eks-demo"
  type    = string
}
