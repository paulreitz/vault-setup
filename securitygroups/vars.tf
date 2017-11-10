variable "aws_region" {}
variable "tfstate_bucket_name" {}
variable "vpc_state_key" {}
variable "prefix" {}
variable "whitelist" {
    default = ["0.0.0.0/0"]
}