variable "tfstate_bucket_name" {}
variable "vpc_state_key" {}
variable "security_groups_state_key" {}
variable "aws_region" {}
variable "dns_zone_id" {}
variable "root_domain" {}
variable "sub_domain" {}
variable "aws_key_pair_name" {}
variable "ui_tag" {}
variable "prefix" {}
variable "instances" {
    default = 1
}