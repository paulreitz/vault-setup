variable "tfstate_bucket_name" {}
variable "vpc_state_key" {}
variable "security_groups_state_key" {}
variable "aws_region" {}
variable "dns_zone_id" {}
variable "root_domain" {}
variable "ui_subdomain" {}
variable "server_subdomain" {}
variable "aws_key_pair_name" {}
variable "ssl_certificate" {}
variable "ui_tag" {}
variable "instances" {
    default = 1
}