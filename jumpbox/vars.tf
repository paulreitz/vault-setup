variable "tfstate_bucket_name" {}
variable "aws_region" {}
variable "vpc_state_key" {}
variable "security_groups_state_key" {}
variable "aws_key_pair_name" {}
variable "prefix" {}
variable "dns_zone_id" {}
variable "root_domain" {}
variable "jumpbox_subdomain" {
    default = "jump2"
}